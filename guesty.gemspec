require_relative 'lib/guesty/version'

Gem::Specification.new do |spec|
  spec.name        = 'guesty'
  spec.version     = Guesty::VERSION
  spec.authors     = ['Guestit']
  spec.summary     = 'Client for the Guesty Open API'
  spec.description = 'HTTP client and operations for the Guesty Open API, decoupled from the host application.'
  spec.license     = 'MIT'
  spec.homepage    = 'https://github.com/guestitab/guesty-client'
  spec.required_ruby_version = '>= 4.0'
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['source_code_uri'] = 'https://github.com/guestitab/guesty-client'
  spec.metadata['changelog_uri'] = 'https://github.com/guestitab/guesty-client/blob/staging/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = %w[CHANGELOG.md LICENSE README.md] + Dir['lib/**/*.rb'] + Dir['sig/**/*.rbs']
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 8.1'
  spec.add_dependency 'dry-monads', '~> 1.10'
  spec.add_dependency 'faraday', '~> 2.14'
  spec.add_dependency 'faraday-retry', '~> 2.4'
  spec.add_dependency 'mini_mime', '~> 1.1'
  spec.add_dependency 'oj', '~> 3.17'
end
