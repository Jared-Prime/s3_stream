require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 's3_stream'
  s.version     = S3Stream::VERSION
  s.summary     = 'Low Memory Access with AWS S3 API'
  s.description = 'Low Memory Access with AWS S3 API'
  s.authors     = ['Jared Davis']
  s.email       = 'dev@kennasecurity.com'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'http://kennasecurity.com'
  s.license     = 'GPL-3.0'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'bundler-audit'
  s.add_development_dependency 'simplecov', '0.15.0'

  s.add_dependency 'fog-aws', '~> 1.4.0'
  s.add_dependency 'require_all', '~> 1.4.0'
  s.add_dependency 'activesupport', '~> 4.2'
  s.add_dependency 'mime-types', '~> 2.99'
end