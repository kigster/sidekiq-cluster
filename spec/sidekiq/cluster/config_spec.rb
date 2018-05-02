require 'spec_helper'

module Sidekiq
  module Cluster
    RSpec.describe Config do
      before do
        described_class.configure do |config|
          config.name       = 'test'
          config.pid_prefix = '/tmp/pidfile.pid'
          config.logfile    = '/tmp/cluster.log'
        end
      end
      subject(:config) { described_class.config }

      its(:name) { should eq 'test' }
      its(:pid_prefix) { should eq '/tmp/pidfile.pid' }
      its(:logfile) { should eq '/tmp/cluster.log' }

      context 'assign' do
        before { config.logfile = 'moo' }
        its(:logfile) { should eq 'moo' }
      end

      context 'split_argv' do
        let(:argv) { %w(-l logfile -P pidfile -- -l sidekiq.log) }
        before { described_class.split_argv(argv) }
        its(:worker_argv) { should eq %w(-l sidekiq.log) }
        its(:cluster_argv) { should eq %w(-l logfile -P pidfile) }

        context 'null worker args' do
          let(:argv) { %w(-l logfile -P pidfile) }
          its(:worker_argv) { should eq %w() }
          its(:cluster_argv) { should eq %w(-l logfile -P pidfile) }
        end

        context 'null args' do
          let(:argv) { %w() }
          its(:worker_argv) { should eq %w() }
          its(:cluster_argv) { should eq %w() }
        end
      end
    end
  end
end

