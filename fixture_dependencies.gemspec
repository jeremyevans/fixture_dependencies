Gem::Specification.new do |s| 
  s.name = "fixture_dependencies"
  s.version = "1.10.0"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.platform = Gem::Platform::RUBY
  s.summary = "Sequel/ActiveRecord fixture loader that handles dependency graphs"
  s.files = ["README.md", "MIT-LICENSE"] + Dir['lib/**/*.rb']
  s.extra_rdoc_files = ["MIT-LICENSE"]
  s.require_paths = ["lib"]
  s.has_rdoc = true
  s.rdoc_options = %w'--inline-source --line-numbers README.md lib'
  s.license = 'MIT'
  s.homepage = "https://github.com/jeremyevans/fixture_dependencies"
end
