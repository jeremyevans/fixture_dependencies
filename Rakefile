require 'rake'
require 'rake/rdoctask'

desc 'Default: generate RDoc.'
task :default => :rdoc

desc 'Generate documentation for the fixture_dependencies plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FixtureDependencies'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
