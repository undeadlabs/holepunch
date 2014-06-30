lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'holepunch/version'

Gem::Specification.new do |spec|
  spec.name           = 'holepunch'
  spec.version        = HolePunch::VERSION
  spec.authors        = [
    'Ben Scott',
    'Pat Wyatt',
  ]
  spec.email          = [
    'gamepoet@gmail.com',
    'pat@codeofhonor.com',
  ]
  spec.summary        = 'Manage AWS security groups in a declarative way'
  spec.description    = IO.read(File.expand_path('../README.md', __FILE__))
  spec.homepage       = 'https://github.com/undeadlabs/holepunch'
  spec.license        = 'MIT'

  spec.files          = Dir.glob('{bin,lib}/**/*')
  spec.executables    = spec.files.grep(%r{bin/}) { |f| File.basename(f) }
  spec.test_files     = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths  = ['lib']

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'thor',    '~> 0.19'
  spec.add_dependency 'aws-sdk', '~> 1.32'

  spec.add_development_dependency 'rake',   '>= 0.8.7'
  spec.add_development_dependency 'rspec',  '~> 3.0'
end
