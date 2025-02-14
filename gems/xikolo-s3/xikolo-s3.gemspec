# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'xikolo-s3'
  spec.version       = '1.5.2'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.description   = 'Xikolo Helper for S3 File handling'
  spec.summary       = 'Xikolo::S3 helpers to access a bucket, object or process an upload'
  spec.homepage      = 'https://dev.xikolo.de/'
  spec.license       = 'Nonstandard'

  spec.files         = Dir['**/*'].grep(%r{((bin|lib|test|spec|features)/|
    .*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)}x)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.4'

  spec.add_dependency 'aws-sdk-s3', '~> 1.16'
  spec.add_dependency 'uuid4', '~> 1.3'
  spec.add_dependency 'xikolo-config'
end
