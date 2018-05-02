require 'forwardable'
require 'state_machines'

require_relative 'worker'
require_relative 'memory'

require_relative 'monitors/oom'
require_relative 'monitors/dead_children'

module Sidekiq
  module Cluster
    class WorkerPool

      include Enumerable

      state_machine :state, initial: :idle do
        event :start do
          transition [:idle] => :starting
        end

        event :started do
          transition [:starting] => :running
        end

        event :stop do
          transition [:idle, :starting, :running, :stopping] => :stopping
        end

        event :shutdown do
          transition [:idle, :starting, :running, :stopping] => :stopped
        end

        after_transition any => :stopped do |pool, _transition|
          pool.cli.stop!
        end

        state :idle, :starting, :started, :stopping, :stopped
      end

      extend Forwardable
      def_delegators :@cli, :info, :error, :print, :stdout, :stdin, :stderr, :kernel
      def_delegators :@workers, :each

      attr_accessor :workers, :config, :cli, :process_count, :monitors

      MONITORS = [Monitors::DeadChildren, Monitors::OOM]

      def initialize(cli, config)
        self.cli           = cli
        self.config        = config
        self.process_count = config.process_count
        self.workers       = []
        self.monitors      = []
        self.state         = :idle

        @signal_received = false
      end

      def spawn
        start!

        create_workers

        info "spawning #{workers.size} workers..."
        workers.each(&:spawn)

        info "worker pids: #{workers.map(&:pid)}"

        setup_signal_traps
        started!

        start_monitors

        info 'startup successful'

        Process.waitall
        monitors.each(&:join)

        info 'all children exited, shutting down'
      end

      def operational?
        shutdown! if stopping?
        stop! if @signal_received
        state_name == :running
      end

      private

      def create_workers
        process_count.times { |index| self.workers << Worker.new(index, cli) }
      end

      def start_monitors
        self.monitors = MONITORS.map { |monitor| monitor.new(self).start }
      end

      def setup_signal_traps
        %w(INT USR1 TERM).each do |sig|
          Signal.trap(sig) do
            handle_signal(sig)
          end
        end
      end

      def handle_signal(sig)
        cli.stderr.puts "received OS signal #{sig}"
        @signal_received = true if (sig == 'INT' || sig == 'TERM' || sig == 'STOP')
        workers.each { |w| w.handle_signal(sig) }
      end
    end
  end
end
