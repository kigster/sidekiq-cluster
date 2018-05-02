#!/usr/bin/env ruby
require 'etc'
require 'optparse'
require 'logger'
require 'colored2'

module Sidekiq
  module Cluster
    MAX_RAM_PCT = 80

    ProcessDescriptor = Struct.new(:pid, :index, :pidfile)

    class CLI
      attr_accessor :name,
                    :pid_prefix,
                    :argv,
                    :sidekiq_argv,
                    :process_count,
                    :pids,
                    :processes,
                    :watch_children,
                    :memory_percentage_limit,
                    :log_device,
                    :logger

      def initialize(argv = ARGV.dup)
        self.argv         = argv
        self.sidekiq_argv = []
      end

      def per_process_memory_limit
        memory_percentage_limit.to_f / process_count.to_f
      end

      def run!
        initialize_cli_arguments!
        print_header!
        start_main_loop!
      end

      def start_main_loop!
        self.processes = {}
        start_children.each do |descriptor|
          processes[descriptor.pid] = descriptor
        end

        self.pids           = processes.keys
        self.watch_children = true

        initiate_main_loop
        setup_signal_traps

        Process.waitall
        info 'shutting down...'
      end

      def print(*args)
        puts(*args)
      end

      def stop!(code = 0)
        Kernel.exit(code)
      end

      def initialize_cli_arguments!
        if argv.nil? || argv.empty?
          argv << '-h'
        else
          split_argv! if argv.include?('--')
        end

        self.log_device              = STDOUT
        self.memory_percentage_limit = MAX_RAM_PCT
        self.process_count           = Etc.nprocessors - 1

        init_logger!
        parse_args!
      end

      private

      def print_header!
        info "starting up sidekiq-cluster for #{name}"
        info "NOTE: cluster max memory limit is #{memory_percentage_limit.round(2)}% of total"
        info "NOTE: per sidekiq memory limit is #{per_process_memory_limit.round(2)}% of total"
      end

      def init_logger!
        self.logger = ::Logger.new(log_device, level: ::Logger::INFO)
      end

      def split_argv!
        self.sidekiq_argv = argv[(argv.index('--') + 1)..-1]
        self.argv         = argv[0..(argv.index('--') - 1)]
      end

      def setup_signal_traps
        %w(INT USR1 TERM).each do |sig|
          Signal.trap(sig) do
            handle_sig(sig)
          end
        end
      end

      def initiate_main_loop
        Thread.new do
          info 'watching for outsized Sidekiq processes...'
          loop do
            sleep 10
            check_pids
            break unless @watch_children
          end
          info 'leaving the main loop..'
        end
      end

      def info(*args)
        @logger.info(*args)
      end

      def error(*args, exception: nil)
        @logger.error("exception: #{exception.message}") if exception
        @logger.error(*args)
      end

      def handle_sig(sig)
        print "received OS signal #{sig}"
        # If we're shutting down, we don't need to re-spawn child processes that die
        @watch_children = false if sig == 'INT' || sig == 'TERM'
        @pids.each do |pid|
          Process.kill(sig, pid)
        end
      end

      def fork_child(index)
        require 'sidekiq'
        require 'sidekiq/cli'

        Process.fork do
          process_argv = sidekiq_argv.dup << '-P' << pid_file(index)
          process_argv << '--tag' << "sidekiq.#{name}"
          info "starting up sidekiq instance #{index} with ARGV: 'bundle exec sidekiq #{process_argv.join(' ')}'"
          begin
            cli = Sidekiq::CLI.instance
            cli.parse process_argv
            cli.run
          rescue => e
            raise e if $DEBUG
            error e.message
            error e.backtrace.join("\n")
            stop!(1)
          end
        end
      end

      def pid_file(index)
        "#{pid_prefix}.#{index}"
      end

      def start_children
        Array.new(process_count) do |index|
          pid = fork_child(index)
          ProcessDescriptor.new(pid, index, pid_file(index))
        end
      end

      def check_pids
        print_info         = false
        @last_info_printed ||= Time.now.to_i
        if Time.now.to_i - @last_info_printed > 60
          @last_info_printed = Time.now.to_i
          print_info         = true
        end

        pids.each do |pid|
          memory_percent_used = `ps -o %mem= -p #{pid}`.to_f
          info "sidekiq.#{name % '%15s'}[#{processes[pid].index}] —— pid=#{pid.to_s % '%6d'} —— memory pct=#{memory_percent_used.round(2)}%" if print_info
          if memory_percent_used == 0.0 # child died
            restart_dead_child(pid)
          elsif memory_percent_used > per_process_memory_limit
            info "pid #{pid} crossed memory threshold, used #{memory_percent_used.round(2)}% of RAM, exceeded #{per_process_memory_limit}% —> replacing..."
            restart_oversized_child(pid)
          elsif $DEBUG
            info "#{pid}: #{memory_percent_used.round(2)}"
          end
        end
      end

      def restart_oversized_child(pid)
        @pids.delete(pid)
        Process.kill('USR1', pid)
        sleep 5
        Process.kill('TERM', pid)
        @pids << fork_child
      end

      def replace_pid(old_pid, new_pid)
        if processes[old_pid]
          pd       = processes[old_pid]
          pid_file = pid_file(pd.index)

          ::File.unlink(pid_file) if ::File.exist?(pidfile)
          pids.delete(old_pid)
          pd.pid = new_pid

          processes.delete(pid)
          processes[new_pid] = pd
        end
      end

      def restart_dead_child(pid)
        info "pid=#{pid} died, restarting..."

        pd      = processes[pid]
        new_pid = fork_child(pd.index)

        replace_pid(pid, new_pid)
        info "replaced lost pid #{pid} with #{new_pid}"
      end

      def parse_args!
        options = {}
        banner  = "USAGE".bold.blue + "\n     sidekiq-cluster [options] -- [sidekiq-options]".bold.green
        parser  = ::OptionParser.new(banner) do |opts|
          opts.separator ''
          opts.separator 'EXAMPLES'.bold.blue
          opts.separator '    $ cd rails_app'.bold.magenta
          opts.separator '    $ bundle exec sidekiq-cluster -N 2 -- -c 10 -q default,12 -l log/sidekiq.log'.bold.magenta
          opts.separator ' '
          opts.separator 'SIDEKIQ CLUSTER OPTIONS'.bold.blue

          opts.on('-n', '--name=NAME',
                  'the name of this cluster, used when ',
                  'when running multiple clusters', ' ') do |v|
            self.name = v
          end
          opts.on('-P', '--pidfile=FILE',
                  'Pidfile prefix, ',
                  'eg "/var/www/shared/config/sidekiq.pid"', ' ') do |v|
            self.pid_prefix = v
          end
          opts.on('-l', '--logfile=FILE',
                  'Logfile for the cluster script', ' ') do |v|
            self.log_device = v
            init_logger!
          end
          opts.on('-M', '--max-memory=PERCENT',
                  'Maximum percent RAM that this',
                  'cluster should not exceed. Defaults to ' +
                      Sidekiq::Cluster::MAX_RAM_PCT.to_s + '%.', ' ') do |v|
            self.memory_percentage_limit = v.to_f
          end
          opts.on('-N', '--num-processes=NUM',
                  'Number of processes to start,',
                  'defaults to number of cores - 1', ' ') do |v|
            self.process_count = v.to_i
          end
          opts.on('-q', '--quiet',
                  'Do not log to STDOUT') do |v|
            self.logger = Logger.new(nil)
          end
          opts.on('-d', '--debug',
                  'Print debugging info before starting sidekiqs') do |_v|
            options[:debug] = true
          end
          opts.on('-h', '--help', 'this help') do |_v|
            self.print opts
            stop!
          end
        end
        parser.order!(argv)
        print("debug: #{self.inspect}") if options[:debug]
      end
    end
  end
end

