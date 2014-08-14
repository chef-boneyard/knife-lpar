# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-fml/version'

Gem::Specification.new do |spec|
  spec.name          = "knife-fml"
  spec.version       = Knife::FML::VERSION
  spec.authors       = ["Scott Hain"]
  spec.email         = ["shain@getchef.com"]
  spec.summary       = %q{Finally Make LPAR}
  spec.description   = spec.summary
  spec.homepage      = "http://github.com/scotthain/knife-fml"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "chef", "~> 11.0"
  spec.add_dependency "net-ssh", "~> 2.6"

  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'simplecov', '~> 0.7.1'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
end
