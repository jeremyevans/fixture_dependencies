require 'rubygems'
require 'sequel'
require 'logger'

begin
  require 'sequel_polymorphic'
rescue LoadError
  puts "Gem 'sequel_polymorphic' was not found. Sequel polymorphic specs will be ignored"
end

DB = Sequel.sqlite(File.join(File.dirname(File.expand_path(__FILE__)), 'db', 'fd_spec.sqlite3'))

require File.join(File.dirname(File.expand_path(__FILE__)),"#{ENV['FD_AR'] ? 'ar' : 'sequel'}_spec_helper")

$:.unshift(File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'lib'))
require 'fixture_dependencies'
FixtureDependencies.fixture_path = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures')
#FixtureDependencies.verbose = 3
FixtureDependencies.class_map[:tag] = Name::Tag
