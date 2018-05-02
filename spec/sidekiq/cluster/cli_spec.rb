require 'spec_helper'

module Sidekiq
  module Cluster
    RSpec.describe CLI do
      let(:argv) { [] }
      let(:cli) {  described_class.new(argv) }
      subject(:config) { cli.config }

      before do
        allow_any_instance_of(described_class).to receive(:info)
        allow_any_instance_of(described_class).to receive(:boot)
        allow_any_instance_of(described_class).to receive(:stop!)
        allow_any_instance_of(described_class).to receive(:print)
      end

      context 'when empty arguments' do
        it 'should print help' do
          cli.execute!
        end
      end

      context 'with empty sidekiq arguments' do
        let(:argv) { %w(-N 2 -q) }

        its(:worker_argv) { should eq %w() }
        its(:cluster_argv) { should eq %w(-N 2 -q)}

        context 'running it' do
          it 'should print help' do
            cli.execute!
          end
        end
      end

      context 'with non-empty sidekiq arguments' do
        let(:argv) { %w(-N 2 -q -- ) }

        its(:worker_argv) { should_not be_nil }
        its(:cluster_argv) { should_not be_nil }

        context 'running it' do
          it 'should print help' do
            cli.execute!
          end
        end
      end

      context 'with non-empty sidekiq arguments' do
        let(:argv) { %w(-N 2 -q -- -l log) }

        context 'running it' do
          before { cli.execute! }

          its(:worker_argv) { should eq %w(-l log)}
          its(:cluster_argv) { should eq %w(-N 2 -q)}
        end
      end
    end
  end
end

