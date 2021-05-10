lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq/cronitor/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-cronitor"
  spec.version       = Sidekiq::Cronitor::VERSION
  spec.authors       = ["Zeke Gabrielse", "Samuel Cochran"]
  spec.email         = ["zeke@keygen.sh", "sj26@sj26.com"]

  spec.summary       = %q{Monitor your Sidekiq jobs with Cronitor}
  spec.description   = %q{Integrates Sidekiq with Cronitor so that workers send lifecycle events - run/complete/fail - around their perform methods}
  spec.homepage      = "https://github.com/cronitor/sidekiq-cronitor"
  spec.license       = "MIT"

  spec.files         = Dir["README.md", "LICENSE", "lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 6.0"
  spec.add_dependency "cronitor", "~> 4.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'bump', '~> 0.1'
end
