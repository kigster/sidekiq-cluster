# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/cluster/version'

Sidekiq::Cluster::DESCRIPTION = <<-eof
  This library provides CLI interface for starting multiple copies of Sidekiq in parallel, typically to take advantage of multi-core systems.  By default it starts N - 1 processes, where N is the number of cores on the current system. Sidekiq Cluster is controlled with CLI flags that appear before `--` (double dash), while any arguments that follow double dash are passed to each Sidekiq process. The exception is the `-P pidfile`, which clustering script passes to each sidekiq process individually.
eof

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-cluster'
  spec.version       = Sidekiq::Cluster::VERSION
  spec.authors       = ['Konstantin Gredeskoul']
  spec.email         = ['kigster@gmail.com']

  spec.summary       = Sidekiq::Cluster::DESCRIPTION
  spec.description   = Sidekiq::Cluster::DESCRIPTION
  spec.homepage      = 'https://github.com/kigster/sidekiq-cluster'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'colored2' 
  spec.add_dependency 'sidekiq' 

  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
