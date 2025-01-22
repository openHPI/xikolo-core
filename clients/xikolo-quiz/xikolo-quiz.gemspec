# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'xikolo-quiz'
  spec.version       = '5.0.0'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.description   = 'Xikolo Quiz Service Client Library'
  spec.summary       = 'Xikolo Quiz Service Client Library'
  spec.homepage      = ''
  spec.license       = ''

  spec.files         = Dir['**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'acfs', '~> 2.0'
  spec.add_dependency 'activesupport'
end
