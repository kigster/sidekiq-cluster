module Sidekiq
  module Cluster
    module Memory
      class Individual
        include MemoryStrategy

        attr_accessor :config, :worker_pool

        def initialize(worker_pool)
          self.worker_pool = worker_pool
          self.config      = worker_pool.config
        end

        def offenders
          worker_pool.find do |worker|
            worker.memory_used_pct > config.max_memory_percent / worker_pool.size
          end
        end
      end
    end
  end
end

