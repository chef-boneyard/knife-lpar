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

  spec.add_dependency "chef", "~> 12.0"
  spec.add_dependency "net-ssh", "~> 2.6"
end
