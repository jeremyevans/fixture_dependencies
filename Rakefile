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
  rdoc.rdoc_files.add ["README", "MIT-LICENSE", "lib/**/*.rb"]
end

desc "Package fixture_dependencies"
task :package do
  sh %{gem build fixture_dependencies.gemspec}
end

begin
  require 'spec/rake/spectask'

  desc "Run Sequel specs"
  Spec::Rake::SpecTask.new(:spec_sequel) do |t|
    t.spec_files = Dir['spec/*_spec.rb']
    #t.rcov = true
  end

  desc "Run ActiveRecord specs"
  Spec::Rake::SpecTask.new(:spec_ar) do |t|
    ENV['FD_AR'] = '1'
    t.spec_files = Dir['spec/*_spec.rb']
    #t.rcov = true
  end

  desc "Run Sequel and ActiveRecord specs"
  task :default=>[:spec_sequel, :spec_ar]
rescue LoadError
end

desc "Create spec database"
task :spec_migrate do
  sh %{mkdir -p spec/db}
  sh %{sequel -m spec/migrate -E sqlite://spec/db/fd_spec.sqlite3}
end
