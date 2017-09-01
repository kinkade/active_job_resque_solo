# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_job_resque_solo/version"

Gem::Specification.new do |spec|
  spec.name          = "active_job_resque_solo"
  spec.version       = ActiveJobResqueSolo::VERSION
  spec.authors       = ["Phillip Kinkade"]
  spec.email         = ["kinkadep@gmail.com"]

  spec.summary       = %q{Prevents duplicate ActiveJob+Resque jobs from being enqueued.}
  spec.description   = %q{If you are using ActiveJob with the Resque Adapter, this gem will help prevent duplicate jobs, based on arguments, from being enqueued to Resque.}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 4.2.0", "< 6"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
