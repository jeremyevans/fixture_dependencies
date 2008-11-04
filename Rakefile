require 'rake'
require 'rake/clean'
begin
  require 'hanna/rdoctask'
rescue LoadError
  require 'rake/rdoctask'
end

CLEAN.include ["rdoc"]

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += ["--quiet", "--line-numbers", "--inline-source"]
  rdoc.main = "README"
  rdoc.title = "fixture_dependencies: Rails fixture loading that works with foreign keys"
  rdoc.rdoc_files.add ["README", "LICENSE", "lib/**/*.rb"]
end

desc "Package fixture_dependencies"
task :package do
  sh %{gem build fixture_dependencies.gemspec}
end
