module Sidekiq
  module Cluster
    module Memory
      class << self
        attr_accessor :strategies

        def offenders(worker_pool)
          name = worker_pool.config.memory_strategy.to_sym
          strategies[name].new(worker_pool).offenders
        end
      end

      self.strategies ||= {}

      module MemoryStrategy
        def self.included(base)
          ::Sidekiq::Cluster::Memory.strategies[base.name.gsub(/.*::/, '').downcase.to_sym] = base
        end
      end
    end
  end
end

require_relative 'memory/individual'
require_relative 'memory/total'
