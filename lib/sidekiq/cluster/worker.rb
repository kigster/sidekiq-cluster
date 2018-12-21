require 'forwardable'
require 'state_machines'

module Sidekiq
  module Cluster
    class Worker

      state_machine :state, initial: :idle do
        event :start do
          transition [:idle] => :starting
        end

        event :started do
          transition [:starting] => :running
        end

        event :stop do
          transition [:idle, :starting, :running] => :stopping
        end

        event :shutdown do
          transition [:idle, :starting, :running, :stopping] => :stopped
        end
      end

      extend Forwardable
      def_delegators :@cli, :info, :error, :print, :stdout, :stdin, :stderr, :kernel, :master_pid

      attr_accessor :pid, :index, :cli, :config, :state

      def initialize(index, cli)
        self.config = cli.config
        self.index  = index
        self.cli    = cli
        self.state  = :idle
      end

      def spawn
        if master?
          cli.info "booting worker #{'%2d' % index} with ARGV '#{config.worker_argv.join(' ')}'"
          self.pid = ::Process.fork do
            # cli.close_logger
            cli.init_logger

            cli.info "child #{index}, running spawn block..."
            begin
              config.spawn_block[self]
            rescue => e
              raise e if $DEBUG
              error e.message
              error e.backtrace.join("\n")
              stop!
            end
          end
        end
        pid
      end

      def memory_used_pct
        self.pid = Process.pid if pid.nil?
        result = `ps -o %mem= -p #{pid}`
        result.nil? || result == '' ? -1 : result.to_f
      end

      def memory_used_percent
        mem = memory_used_pct
        mem < 0 ? 'DEAD' : sprintf('%.2f%%', mem)
      end

      def check_worker
        self.pid = Process.pid if pid.nil?
        respawn! if memory_used_pct == -1 && master?
      end

      def respawn!
        if master? && pid
          cli.info "NOTE: re-spawning child #{index} (pid #{pid}), memory is at #{memory_used_percent}."
          begin
            Process.kill('USR1', pid)
            sleep 5
            Process.kill('TERM', pid)
          rescue Errno::ESRCH
            nil
          end
          self.pid = nil
          spawn
        end
      end

      def handle_signal(sig)
        Process.kill(sig, pid) if pid
      rescue Errno::ESRCH
        nil
      end

      def pid_file
        "#{config.pid_prefix}.#{index + 1}"
      end

      def master?
        Process.pid == cli.master_pid
      end

      def log_worker
        cli.info(status) if memory_used_pct >= 0.0
      end

      def status
        "worker.#{config.name}[index=#{index}, pid=#{pid ? pid : 'nil'}] —— memory: #{memory_used_percent}"
      end
    end
  end
end

