require 'spec_helper'

module Sidekiq
  module Cluster
    RSpec.describe Memory do
      subject(:strategies) { Memory.strategies }

      its(:size) { should eq 2 }
      its(:keys) { should =~ %i(total individual) }

    end
  end
end

