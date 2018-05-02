require_relative 'base'

module Sidekiq
  module Cluster
    module Monitors
      class DeadChildren < Base
        def monitor
          pool.info 'watching for workers that died...'
          loop do
            sleep SLEEP_DELAY - 1
            pool.workers.each(&:check_worker)
            break unless pool.operational?
            "monitor for Dead Children is operational, last logged at #{@last_logged_at}"
          end
          pool.info 'leaving Dead Children Monitor'
        end
      end
    end
  end
end

