require_relative 'dead_children'
require_relative '../memory'
module Sidekiq
  module Cluster
    module Monitors
      class OOM < Base
        def monitor
          pool.info 'watching for worker processes exceeding size threshold'
          loop do
            sleep SLEEP_DELAY + 1
            ::Sidekiq::Cluster::Memory.offenders(pool).each { |worker| worker.respawn! }
            break unless pool.operational?
            log_periodically "monitor for Out Of Memory is operational, last logged at #{@last_logged_at}" do
              pool.workers.map(&:status)
            end
          end
          pool.info 'leaving Memory Monitor.'
        end
      end
    end
  end
end
