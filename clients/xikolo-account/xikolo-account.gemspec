# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'xikolo-account'
  spec.version       = '8.0.1'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.description   = 'Xikolo Account Service Client Library'
  spec.summary       = 'Xikolo Account Service Client Library'
  spec.homepage      = ''
  spec.license       = ''

  spec.files         = Dir['**/*'].grep(%r{((bin|lib|test|spec|features)/|
    .*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)}x)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'acfs', '~> 2.0'
  spec.add_dependency 'activesupport'
end
