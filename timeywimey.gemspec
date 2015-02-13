# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'timeywimey/version'

Gem::Specification.new do |spec|
  spec.name          = "timeywimey"
  spec.version       = Timeywimey::VERSION
  spec.authors       = ["Ryan Canty"]
  spec.email         = ["rcanty@qti.qualcomm.com"]
  spec.summary       = %q{Wraps up time_ago_in_words to use outside of ActionView}
  spec.description   = %q{Timeywimey wraps up several active_support modules and gives you access to time_ago_in_words outside the ActionView context or in a native Ruby app.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_runtime_dependency "activesupport"
end
