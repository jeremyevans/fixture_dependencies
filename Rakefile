require 'rake'
require 'rake/clean'

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source"]

rdoc_task_class = begin
  require "rdoc/task"
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
  RDoc::Task
rescue LoadError
  begin
    require "rake/rdoctask"
    Rake::RDocTask
  rescue LoadError, StandardError
  end
end

CLEAN.include ["rdoc"]

rdoc_task_class.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_DEFAULT_OPTS
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
  task :spec_ar do
    sh %{#{FileUtils::RUBY} -S rake spec_sequel FD_AR=1}
  end

  desc "Run Sequel and ActiveRecord specs"
  task :default=>[:spec_migrate, :spec_sequel, :spec_ar]
rescue LoadError
end

desc "Create spec database"
task :spec_migrate do
  sh %{mkdir -p spec/db}
  sh %{#{FileUtils::RUBY} -S sequel -m spec/migrate -E sqlite://spec/db/fd_spec.sqlite3}
end
