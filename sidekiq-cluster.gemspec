# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-cluster'
  spec.version       = '0.1.2'
  spec.authors       = ['Konstantin Gredeskoul']
  spec.email         = ['kigster@gmail.com']

  spec.summary       = 'Foo Bar'
  spec.description   = 'Foo Bar'
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
  spec.add_dependency 'dry-configurable'
  spec.add_dependency 'state_machines'

  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
