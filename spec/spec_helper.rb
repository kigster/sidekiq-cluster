require 'simplecov'
require 'rspec'
require 'rspec/its'
SimpleCov.start

require 'rspec'
require 'sidekiq/cluster'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
