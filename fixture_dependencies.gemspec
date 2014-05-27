spec = Gem::Specification.new do |s| 
  s.name = "fixture_dependencies"
  s.version = "1.3.3"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.platform = Gem::Platform::RUBY
  s.summary = "Sequel/ActiveRecord fixture loader that handles dependency graphs"
  s.files = ["README", "MIT-LICENSE", "lib/fixture_dependencies.rb", "lib/fixture_dependencies_test_help.rb", "lib/fixture_dependencies/sequel.rb", "lib/fixture_dependencies/active_record.rb", "lib/fixture_dependencies/test_unit.rb", "lib/fixture_dependencies/test_unit/rails.rb", "lib/fixture_dependencies/test_unit/sequel.rb", "lib/fixture_dependencies/rspec/sequel.rb"]
  s.extra_rdoc_files = ["MIT-LICENSE"]
  s.require_paths = ["lib"]
  s.has_rdoc = true
  s.rdoc_options = %w'--inline-source --line-numbers README lib'
  s.license = 'MIT'
  s.homepage = "https://github.com/jeremyevans/fixture_dependencies"
end
