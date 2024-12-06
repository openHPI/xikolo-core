# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'xikolo-config'
  spec.version       = '8.0'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.description   = 'Xikolo Configuration Helper'
  spec.summary       = 'Xikolo Configuration Helper'
  spec.homepage      = ''
  spec.license       = ''

  spec.files         = Dir['**/*'].grep(%r{((bin|lib|test|spec|features)/|
    .*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)}x)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'addressable', '~> 2.0'
end
