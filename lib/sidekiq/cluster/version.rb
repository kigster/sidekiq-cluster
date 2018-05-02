# frozen_string_literal: true

require 'colored2'

module Sidekiq
  module Cluster
    VERSION ||= '0.1.2'

    DESCRIPTION = <<-eof
      This library provides CLI interface for starting multiple copies of Sidekiq in parallel, 
      typically to take advantage of multi-core systems.  By default it starts N - 1 processes, 
      where N is the number of cores on the current system. Sidekiq Cluster is controlled with CLI 
      flags that appear before `--` (double dash), while any arguments that follow double dash are 
      passed to each Sidekiq process. The exception is the `-P pidfile`, which clustering script 
      passes to each sidekiq process individually.
    eof
                      .gsub(/\n    /, ' ').freeze

    MAX_RAM_PCT ||= 80.freeze

    # @formatter:off
      BANNER ||= %Q(
#{'EXAMPLES'.bold.yellow}

    $ cd rails_app
    $ echo 'gem "sidekiq-cluster"' >> Gemfile
    $ bundle install
    #{'$ bundle exec sidekiq-cluster -N 2 '.bold.magenta + '--' + ' -c 10 -q default,12 -L log/sidekiq.log'.bold.cyan}

#{'OPTIONS'.bold.yellow}
).freeze
      # @formatter:on
  end
end

