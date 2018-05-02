require 'spec_helper'

module Sidekiq
  module Cluster
    RSpec.describe CLI do
      let(:argv) { [] }
      subject(:cli) { described_class.new(argv) }

      context 'when empty arguments' do
        it 'should print help' do
          expect_any_instance_of(described_class).to receive(:print)
          expect_any_instance_of(described_class).to receive(:stop!)
          cli.initialize_cli_arguments!
        end
      end

      context 'with empty sidekiq arguments' do
        let(:argv) { %w(-N 2 -q) }

        its(:sidekiq_argv) { should_not be_nil }
        its(:sidekiq_argv) { should be_empty }

        context 'running it' do
          before { expect(cli).to receive(:start_main_loop!) }
          it 'should print help' do
            cli.run!
          end
        end
      end

      context 'with non-empty sidekiq arguments' do
        let(:argv) { %w(-N 2 -q -- ) }

        its(:sidekiq_argv) { should_not be_nil }
        its(:sidekiq_argv) { should be_empty }

        context 'running it' do
          before { expect(cli).to receive(:start_main_loop!) }
          it 'should print help' do
            cli.run!
          end
        end
      end

      context 'with non-empty sidekiq arguments' do
        let(:argv) { %w(-N 2 -q -- -l log) }

        context 'running it' do
          before do
            expect(cli).to receive(:start_main_loop!)
            cli.run!
          end

          its(:sidekiq_argv) { should_not be_empty }
          its(:sidekiq_argv) { should eq %w(-l log) }

        end
      end
    end
  end
end

