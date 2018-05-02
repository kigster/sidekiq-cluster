#!/usr/bin/env ruby
require 'etc'
require 'optparse'
require 'logger'
require 'colored2'
require 'pp'

require_relative 'config'
require_relative 'worker_pool'
require_relative 'version'

module Sidekiq
  module Cluster
    class CLI
      attr_accessor :argv, :config, :logger, :log_device, :worker_pool, :master_pid
      attr_reader :stdout, :stdin, :stderr, :kernel

      class << self
        attr_accessor :instance
      end

      def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
        @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
        args                                     = argv.dup
        args                                     = %w(--help) if args.nil? || args.empty?
        self.master_pid                          = Process.pid
        self.config                              = Config.config
        Config.split_argv(args.dup)
        self.class.instance = self
      end

      def execute!
        parse_cli_arguments
        print_header
        pp config.to_h if config.debug

        ::Process.setproctitle('sidekiq-cluster.' + config.name + ' ' + config.cluster_argv.join(' '))

        if config.work_dir
          if Dir.exist?(config.work_dir)
            Dir.chdir(config.work_dir)
          else
            raise "Can not find work dir #{config.work_dir}"
          end
        end

        config.logfile    = Dir.pwd + '/' + config.logfile if config.logfile && !config.logfile.start_with?('/')
        config.pid_prefix = Dir.pwd + '/' + config.pid_prefix if config.pid_prefix && !config.pid_prefix.start_with?('/')

        init_logger

        boot
      end

      def boot
        @worker_pool = ::Sidekiq::Cluster::WorkerPool.new(self, config)
        @worker_pool.spawn
      end

      def print(*args)
        unless config.quiet
          stdout.puts args.join(' ')
        end
      end

      def stop!(code = 0)
        if worker_pool
          unless worker_pool.stopped?
            worker_pool.stop!
            sleep 5
          end
        end

        kernel.exit(code)
      end

      def close_logger
        self.logger.close if logger && logger.respond_to?(:close)
        if Process.pid != master_pid
          log_device.close if log_device && log_device.respond_to?(:close)
        end
      rescue
        nil
      end

      def init_logger
        if config.logfile
          ::FileUtils.mkdir_p(::File.dirname(config.logfile))
          self.log_device = ::File.open(config.logfile, 'a', 0644)
        else
          self.log_device = stdout
        end

        log_device.sync = true

        @logger = ::Logger.new(log_device, level: ::Logger::INFO)
        info('opening log file: ' + (config.logfile ? config.logfile.to_s : 'STDOUT'))
      end

      def print_header
        print "Sidekiq Cluster v#{Sidekiq::Cluster::VERSION} — Starting up, Cluster name: [#{config.name}]"
        print "  • max memory limit is  : #{config.max_memory_percent.round(2)}%"
        print "  • memory strategy      : #{config.memory_strategy.to_s.capitalize}"
        print "  • number of workers is : #{config.process_count}"
        print "  • logfile              : #{config.logfile}" if config.logfile
        print "  • pid file path        : #{config.pid_prefix}" if config.pid_prefix
      end

      def prefix
        Process.pid == master_pid ? ' «master» '.bold.blue : ' «worker» '.bold.green
      end

      def info(*args)
        logger.info(prefix + args.join(' '))
      end

      def error(*args, exception: nil)
        logger.error(prefix + "exception: #{exception.message}") if exception
        logger.error(prefix + args.join(' '))
      end

      private

      def parse_cli_arguments
        banner = 'USAGE'.bold.yellow + "\n    sidekiq-cluster [options] -- ".bold.magenta + "[sidekiq-options]".bold.cyan
        parser = ::OptionParser.new(banner, 26, indent = ' ' * 3) do |opts|
          opts.separator ::Sidekiq::Cluster::BANNER
          opts.on('-n', '--name NAME',
                  'the name of this cluster, used when running ',
                  'multiple clusters.', ' ') do |v|
            config.name = v
          end
          opts.on('-N', '--num-processes NUM',
                  'Number of worker processes to use for this cluster,',
                  'defaults to the number of cores - 1', ' ') do |v|
            config.process_count = v.to_i
          end

          opts.on('-M', '--max-memory PCT',
                  'Float, the maximum percent total RAM that this',
                  'cluster should not exceed. Defaults to ' +
                      Sidekiq::Cluster::MAX_RAM_PCT.to_s + '%.', ' ') do |v|
            config.max_memory_percent = v.to_f
          end

          opts.on('-m', '--memory-mode MODE',
                  'Either "total" (default) or "individual".', ' ',
                  '• In the "total" mode the largest worker is restarted if ',
                  '  the sum of all workers exceeds the memory limit. ',
                  '• In the "individual" mode, a worker is restarted if it ',
                  '  exceeds MaxMemory / NumWorkers.', ' ') do |v|
            if Config::MEMORY_STRATEGIES.include?(v.downcase.to_sym)
              config.memory_strategy = v.downcase.to_sym
            else
              raise "Invalid strategy '#{v}'. Valid strategies are :#{Config::MEMORY_STRATEGIES.join(', ')}"
            end
          end

          opts.on('-P', '--pid-prefix PATH',
                  'Pidfile prefix path used to generate pid files, ',
                  'eg "/var/tmp/cluster.pid"', ' ') do |v|
            config.pid_prefix = v
          end

          opts.on('-L', '--logfile FILE',
                  'The logfile for sidekiq cluster itself', ' ') do |v|
            config.logfile = v
          end

          opts.on('-w', '--work-dir DIR',
                  'Directory where to run', ' ') do |v|
            config.work_dir = v
          end

          opts.on('-q', '--quiet',
                  'Do not print anything to STDOUT') do |_v|
            config.quiet = true
          end

          opts.on('-d', '--debug',
                  'Print debugging info before starting workers') do |_v|
            config.debug = true
          end

          opts.on('-h', '--help', 'this help') do |_v|
            config.help = true
            stdout.puts opts
            stop!
          end
        end

        parser.order!(argv.dup)
      end
    end
  end
end

