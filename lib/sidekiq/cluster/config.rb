require 'etc'
require 'dry-configurable'
require_relative 'version'

module Sidekiq
  module Cluster
    class Config
      MEMORY_STRATEGIES = %i(total individual)
      ARGV_SEPARATOR = '--'.freeze

      extend ::Dry::Configurable

      setting :spawn_block, ->(worker) {
        require 'sidekiq'
        require 'sidekiq/cli'

        process_argv = worker.config.worker_argv.dup << '-P' << worker.pid_file
        process_argv << '--tag' << "sidekiq.#{worker.config.name}.#{worker.index + 1}"

        cli = Sidekiq::CLI.instance
        cli.parse %w(bundle exec sidekiq) + process_argv
        cli.run
      }

      setting :name, 'default'
      setting :pid_prefix, '/var/tmp/sidekiq-cluster.pid'
      setting :process_count, Etc.nprocessors - 1
      setting :max_memory_percent, MAX_RAM_PCT
      setting :memory_strategy, :total # also supported :individual
      setting :logfile
      setting :work_dir, Dir.pwd
      setting :cluster_argv, []
      setting :worker_argv, []
      setting :debug, false
      setting :quiet, false
      setting :help, false


      def self.split_argv(argv)
        configure do |c|
          if argv.index(ARGV_SEPARATOR)
            c.worker_argv  = argv[(argv.index(ARGV_SEPARATOR) + 1)..-1] || []
            c.cluster_argv = argv[0..(argv.index(ARGV_SEPARATOR) - 1)] || []
          else
            c.worker_argv = []
            c.cluster_argv = argv
          end
        end
      end
    end
  end
end

