if command = ENV.delete('COVERAGE')
  require 'simplecov'

  SimpleCov.start do
    command_name command
    coverage :line
    coverage :branch
    cover "lib/fixture_dependencies{,/sequel,/active_record}.rb"
    group('Missing'){|src| src.covered_percent < 100}
    merge_timeout 600
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
