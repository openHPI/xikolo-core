# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'xikolo-sidekiq'
  spec.version       = '4.0.0'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.description   = 'Xikolo Setup for Sidekiq'
  spec.summary       = 'Queues, Cronjobs, Background Workers, Rake tasks'
  spec.homepage      = 'https://dev.xikolo.de/'
  spec.license       = 'Nonstandard'

  spec.files         = Dir['**/*'].grep(%r{((bin|lib|test|spec|features)/|
    .*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)}x)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'railties'
  spec.add_dependency 'sidekiq', '~> 7.0'
end
