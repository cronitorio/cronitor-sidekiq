lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq/cronitor/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-cronitor"
  spec.version       = Sidekiq::Cronitor::VERSION
  spec.author        = "Samuel Cochran"
  spec.email         = "sj26@sj26.com"

  spec.summary       = %q{Monitor your sidekiq jobs with Cronitor}
  spec.description   = %q{Integrates sidekiq with cronitor so that workers call run/complete/failed around their perform methods}
  spec.homepage      = "https://github.com/sj26/sidekiq-cronitor"
  spec.license       = "MIT"

  spec.files         = Dir["README.md", "LICENSE", "lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 5.0"
  spec.add_dependency "cronitor", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
