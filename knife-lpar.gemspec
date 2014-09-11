# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-lpar/version'

Gem::Specification.new do |spec|
  spec.name          = "knife-lpar"
  spec.version       = Knife::Lpar::VERSION
  spec.authors       = ["Scott Hain"]
  spec.email         = ["shain@getchef.com"]
  spec.summary       = %q{LPAR creation}
  spec.description   = spec.summary
  spec.homepage      = "http://github.com/opscode/knife-lpar"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "chef", "~> 11.0"
  spec.add_dependency "net-ssh", "~> 2.6"

  %w(rspec-core rspec-expectations rspec-mocks).each { |gem| spec.add_development_dependency gem }
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
end
