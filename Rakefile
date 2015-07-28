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

CLEAN.include ["rdoc", "spec/db/fd_spec.sqlite3"]

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

desc "Run Sequel and ActiveRecord specs"
task :default=>[:spec_migrate, :spec_sequel, :spec_ar]

desc "Run Sequel specs"
task :spec_sequel do
  sh "#{FileUtils::RUBY} -I lib spec/fd_spec.rb"
end

desc "Run ActiveRecord specs"
task :spec_ar do
  ENV['FD_AR'] = '1'
  sh "#{FileUtils::RUBY} -I lib spec/fd_spec.rb"
  ENV.delete('FD_AR')
end

desc "Create spec database"
task :spec_migrate do
  unless File.exist?('spec/db/fd_spec.sqlite3')
    sh %{mkdir -p spec/db}
    sh %{#{FileUtils::RUBY} -S sequel -m spec/migrate sqlite://spec/db/fd_spec.sqlite3}
  end
end
