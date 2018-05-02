require_relative '../stdlib_ext'
require_relative 'individual'
module Sidekiq
  module Cluster
    module Memory
      class Total < Individual
        include MemoryStrategy

        def offenders
          total_ram_pct = worker_pool.map(&:memory_used_pct).sum
          worker_pool.cli.info("total RAM used by workers is #{'%.2f%%' % total_ram_pct}")
          if total_ram_pct > config.max_memory_percent
            worker_pool.sort_by(&:memory_used_pct).inverse[0..1]
          end || []
        end
      end
    end
  end
end

