require 'rubygems'
require 'logger'

if coverage = ENV.delete('COVERAGE')
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    command_name coverage
    add_filter "/spec/"
    add_group('Missing'){|src| src.covered_percent < 100}
    add_group('Covered'){|src| src.covered_percent == 100}
  end
end

require File.join(File.dirname(File.expand_path(__FILE__)),"#{ENV['FD_AR'] ? 'ar' : 'sequel'}_spec_helper")

$:.unshift(File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'lib'))
require 'fixture_dependencies'
FixtureDependencies.fixture_path = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures')
#FixtureDependencies.verbose = 3
FixtureDependencies.class_map[:tag] = Name::Tag
FixtureDependencies.class_map[:cm_artist] = ClassMap::CmArtist
FixtureDependencies.class_map[:cm_album] = ClassMap::CmAlbum
