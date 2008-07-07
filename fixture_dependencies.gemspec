spec = Gem::Specification.new do |s| 
  s.name = "fixture_dependencies"
  s.version = "1.0.0"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.platform = Gem::Platform::RUBY
  s.summary = "Rails fixture loading that works with foreign keys"
  s.files = ["README", "LICENSE", "lib/fixture_dependencies.rb", "lib/fixture_dependencies_test_help.rb"]
  s.extra_rdoc_files = ["LICENSE"]
  s.require_paths = ["lib"]
  s.has_rdoc = true
  s.rdoc_options = %w'--inline-source --line-numbers README lib'
end
