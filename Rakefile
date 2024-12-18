require 'rake/clean'
require "rdoc/task"

CLEAN.include ["rdoc", "spec/db/fd_spec.sqlite3", "coverage", "*.gem"]

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'fixture_dependencies: Sequel/ActiveRecord fixture loader that handles dependency graphs', '--main', 'README.md']

  begin
    gem 'hanna'
    rdoc.options += ['-f', 'hanna']
  rescue Gem::LoadError
  end

  rdoc.rdoc_files.add %w"README.md MIT-LICENSE CHANGELOG lib/**/*.rb"
end

desc "Package fixture_dependencies"
task :package do
  sh %{gem build fixture_dependencies.gemspec}
end

all_specs = [:spec_migrate, :spec_sequel]
all_specs << :spec_ar unless RUBY_ENGINE == 'jruby'
desc "Run Sequel and ActiveRecord specs"
task :default=>all_specs

test_flags = String.new
test_flags << '-w ' if RUBY_VERSION >= '3'
test_flags << '-W:strict_unused_block ' if RUBY_VERSION >= '3.4'

desc "Run Sequel specs"
task :spec_sequel do
  sh "#{FileUtils::RUBY} #{test_flags} spec/fd_spec.rb"
end

desc "Run ActiveRecord specs"
task :spec_ar do
  ENV['FD_AR'] = '1'
  sh "#{FileUtils::RUBY} #{test_flags} spec/fd_spec.rb"
  ENV.delete('FD_AR')
end

desc "Create spec database"
task :spec_migrate do
  unless File.exist?('spec/db/fd_spec.sqlite3')
    sh %{mkdir -p spec/db}
    sh %{#{FileUtils::RUBY} -S sequel -m spec/migrate #{RUBY_ENGINE == 'jruby' ? 'jdbc:sqlite:spec/db/fd_spec.sqlite3' : 'sqlite://spec/db/fd_spec.sqlite3'}}
  end
end

desc "Run specs with coverage"
task :spec_cov do
  ENV['COVERAGE'] = 'sequel'
  sh "#{FileUtils::RUBY} spec/fd_spec.rb"
  ENV['COVERAGE'] = 'active_record'
  ENV['FD_AR'] = '1'
  sh "#{FileUtils::RUBY} spec/fd_spec.rb"
end
