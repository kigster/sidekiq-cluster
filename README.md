[![Build Status](https://travis-ci.org/kigster/sidekiq-cluster.svg?branch=master)](https://travis-ci.org/kigster/sidekiq-cluster)

## Sidekiq Cluster

This is a tiny gem that allows starting sidekiq using multiple processes. 

It does not depend on any particular version of sidekiq, as long as the CLI class of Sidekiq remains named the same.

### Usage

Install the gem:

```
gem install sidekiq-cluster
```

Then try running it with `--help`:

```
sidekiq-cluster -h

USAGE
     sidekiq-cluster [options] -- [sidekiq-options]

EXAMPLES
    $ cd rails_app
    $ bundle exec sidekiq-cluster -N 2 -- -c 10 -q default,12 -l log/sidekiq.log
 
SIDEKIQ CLUSTER OPTIONS
    -n, --name=NAME                  the name of this cluster, used when 
                                     when running multiple clusters
                                      
    -P, --pidfile=FILE               Pidfile prefix, 
                                     eg "/var/www/shared/config/sidekiq.pid"
                                      
    -l, --logfile=FILE               Logfile for the cluster script
                                      
    -M, --max-memory=PERCENT         Maximum percent RAM that this
                                     cluster should not exceed. Defaults to 80%.
                                      
    -N, --num-processes=NUM          Number of processes to start,
                                     defaults to number of cores - 1
                                      
    -q, --quiet                      Do not log to STDOUT
    -d, --debug                      Print debugging info before starting sidekiqs
    -h, --help                       this help


```

## Examples

```bash
$ cd rails-app
$ echo "gem 'sidekiq-cluster'" >> Gemfile
$ bundle install
$ bundle exec sidekiq-cluster \
    -P /var/pids/sidekiq.pid \  # these are arguments to sidekiq-cluster
    -n default \
    -M 90 \
    -L /var/log/sidekiq-cluster.log \
    -N 2 \  
    -- \                        # these are arguments for sidekiq.
    -L /var/log/sidekiq.log -c 10 -e production -q default,10 -q critical,20
```

## Contributing to sidekiq-cluster
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright © 2018 Konstantin Gredeskoul. See LICENSE.txt for further details.

