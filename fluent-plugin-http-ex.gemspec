# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-http-ex"
  spec.version       = "0.0.1"
  spec.authors       = ["hiro-su"]
  spec.email         = ["h.sugipon@gmail.com"]
  spec.description   = %q{fluent plugin to accept multiple json/msgpack events in one HTTP request}
  spec.summary       = %q{fluent plugin to accept multiple json/msgpack events in one HTTP request}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "fluentd"
  spec.add_runtime_dependency "fluentd"
end
