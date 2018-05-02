module Sidekiq
  module Cluster
    module Monitors
      SLEEP_DELAY = 5
      LOGGING_PERIOD = 30

      class Base
        attr_accessor :pool, :thread

        def initialize(pool)
          self.pool = pool
          @last_logged_at = Time.now.to_i
        end

        def start
          self.thread = Thread.new { self.monitor }
          self
        end

        def join
          thread.join if thread
        end

        def monitor
          raise 'Abstract method'
        end

        def log_periodically(msg, &block)
          t = Time.now.to_i
          if t - @last_logged_at > LOGGING_PERIOD
            pool.cli.info(msg) if msg
            Array(block.call).each do |result|
              pool.cli.info(result)
            end if block
            @last_logged_at = t
          end
        end
      end
    end
  end
end

