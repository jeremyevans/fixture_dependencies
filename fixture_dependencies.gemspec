Gem::Specification.new do |s| 
  s.name = "fixture_dependencies"
  s.version = "1.11.0"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.platform = Gem::Platform::RUBY
  s.summary = "Sequel/ActiveRecord fixture loader that handles dependency graphs"
  s.files = ["README.md", "MIT-LICENSE", "CHANGELOG"] + Dir['lib/**/*.rb']
  s.extra_rdoc_files = ["MIT-LICENSE"]
  s.require_paths = ["lib"]
  s.rdoc_options = %w'--inline-source --line-numbers README.md lib'
  s.license = 'MIT'
  s.homepage = "https://github.com/jeremyevans/fixture_dependencies"
  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/jeremyevans/fixture_dependencies/issues',
    'mailing_list_uri'  => 'https://github.com/jeremyevans/fixture_dependencies/discussions',
    'source_code_uri'   => 'https://github.com/jeremyevans/fixture_dependencies',
  }
  s.required_ruby_version = ">= 1.9.2"
  s.add_development_dependency "minitest-global_expectations"
end
