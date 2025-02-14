# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'xikolo-common'
  spec.version       = '2.18.0'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.summary       = 'Xikolo Shared Stuff'
  spec.homepage      = ''
  spec.license       = 'Nonstandard'

  spec.files         = Dir['**/*'].grep(%r{((bin|lib|test|spec|features)/|
    .*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)}x)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.4'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'addressable', '~> 2'
  spec.add_dependency 'lograge', '~> 0.3.5'
  spec.add_dependency 'railties'
  spec.add_dependency 'restify', '~> 1.6'
  spec.add_dependency 'telegraf'
end
