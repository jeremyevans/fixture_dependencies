require 'rake/clean'

CLEAN.include ["rdoc", "spec/db/fd_spec.sqlite3", "coverage", "*.gem"]

desc "Generate rdoc"
task :rdoc do
  rdoc_dir = "rdoc"
  rdoc_opts = ["--line-numbers", "--inline-source", '--title', 'fixture_dependencies: Sequel/ActiveRecord fixture loader that handles dependency graphs']

  begin
    gem 'hanna'
    rdoc_opts.concat(['-f', 'hanna'])
  rescue Gem::LoadError
  end

  rdoc_opts.concat(['--main', 'README.md', "-o", rdoc_dir] +
    %w"README.md CHANGELOG MIT-LICENSE" +
    Dir["lib/**/*.rb"]
  )

  FileUtils.rm_rf(rdoc_dir)

  require "rdoc"
  RDoc::RDoc.new.document(rdoc_opts)
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
