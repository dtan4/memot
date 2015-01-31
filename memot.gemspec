# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'memot/version'

Gem::Specification.new do |spec|
  spec.name          = "memot"
  spec.version       = Memot::VERSION
  spec.authors       = ["dtan4"]
  spec.email         = ["dtanshi45@gmail.com"]
  spec.description   = %q{Markdown Memo Management Library}
  spec.summary       = %q{Markdown Memo Management Library}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "dropbox-sdk"
  spec.add_dependency "evernote_oauth"
  spec.add_dependency "redcarpet"

  spec.add_dependency "redis"
  spec.add_dependency "hiredis"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"
end
