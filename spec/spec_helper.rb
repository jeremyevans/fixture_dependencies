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

require_relative "#{ENV['FD_AR'] ? 'ar' : 'sequel'}_spec_helper"

require_relative '../lib/fixture_dependencies'
FixtureDependencies.fixture_path = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures')
FixtureDependencies.class_map[:tag] = Name::Tag
FixtureDependencies.class_map[:cm_artist] = ClassMap::CmArtist
FixtureDependencies.class_map[:cm_album] = ClassMap::CmAlbum
FixtureDependencies.class_map[:mc_artist] = ClassMap::MCArtist
FixtureDependencies.class_map[:mc_album] = ClassMap::MCAlbum
