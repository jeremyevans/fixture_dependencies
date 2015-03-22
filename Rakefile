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
  begin
    raise LoadError if ENV['RSPEC1']
    # RSpec 2
    require "rspec/core/rake_task"
    spec_class = RSpec::Core::RakeTask
    spec_files_meth = :pattern=
  rescue LoadError
    # RSpec 1
    require "spec/rake/spectask"
    spec_class = Spec::Rake::SpecTask
    spec_files_meth = :spec_files=
  end

  desc "Run Sequel specs"
  spec_class.new(:spec_sequel) do |t|
    t.send(spec_files_meth, Dir['spec/fd_spec.rb'])
  end

  desc "Run Sequel/RSpec integration specs"
  spec_class.new(:spec_rspec_sequel) do |t|
    t.send(spec_files_meth, Dir['spec/fd_rspec_spec.rb'])
  end

  RAKE = ENV['RAKE'] || "#{FileUtils::RUBY} -S rake"
  desc "Run ActiveRecord specs"
  task :spec_ar do
    sh %{#{RAKE} spec_sequel FD_AR=1}
  end

  desc "Run Sequel and ActiveRecord specs"
  task :default=>[:spec_migrate, :spec_sequel, :spec_ar, :spec_rspec_sequel]
rescue LoadError
end

desc "Create spec database"
task :spec_migrate do
  sh %{mkdir -p spec/db}
  sh %{#{FileUtils::RUBY} -S sequel -m spec/migrate sqlite://spec/db/fd_spec.sqlite3}
end
