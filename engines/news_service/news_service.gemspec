# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'news_service'
  spec.version       = '0.0.1'
  spec.authors       = ['Xikolo Development Team']
  spec.email         = %w[xikolo-dev@hpi.uni-potsdam.de]
  spec.homepage      = 'https://dev.xikolo.de/'
  spec.summary       = 'News service as a Rails Engine.'
  spec.description   = 'Manage news and announcements.'
  spec.license       = 'Nonstandard'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or `delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = 'do-not-push'

  spec.metadata['homepage_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*']
  end

  spec.required_ruby_version = '>= 3.4'
end
