# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'xui-form'
  spec.version       = '0.0.1'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.summary       = 'A form builder library'
  spec.homepage      = ''
  spec.license       = 'Nonstandard'

  spec.files         = Dir['**/*'].grep(%r{((bin|lib|test|spec|features)/|
    .*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)}x)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.4'

  spec.add_dependency 'activemodel'
  spec.add_dependency 'uuid4', '~> 1.3'
  spec.add_dependency 'xikolo-config'
end
