# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'vcloud/edge_gateway/version'
Gem::Specification.new do |s|
  s.name        = 'vcloud-edge_gateway'
  s.version     = Vcloud::EdgeGateway::VERSION
  s.authors     = ['Anna Shipman']
  s.email       = ['anna.shipman@digital.cabinet-office.gov.uk']
  s.summary     = 'Tool to configure a VMware vCloud Edge Gateway'
  s.description = 'Tool to configure a VMware vCloud Edge Gateway. Uses vcloud-core.'
  s.homepage    = 'http://github.com/alphagov/vcloud-edge_gateway'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) {|f| File.basename(f)}
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.2'

  s.add_runtime_dependency 'fog', '>= 1.19.0'
  s.add_runtime_dependency 'vcloud-core'
  s.add_runtime_dependency 'hashdiff'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.14.1'
  s.add_development_dependency 'simplecov', '~> 0.8.2'
end
