require 'active_record'

ActiveRecord::Base.establish_connection(:adapter=>'sqlite3', :database=>File.join(File.dirname(File.expand_path(__FILE__)), 'db', 'fd_spec.sqlite3'))

class Artist < ActiveRecord::Base
  has_many :albums
end

class ArtistCustomFixture < Artist
  def self.fixture_filename
    :artists_custom_fixture_file
  end
  has_one :first_album, :class_name=>'Album', :foreign_key=>:artist_id
end

module Name; end
class Name::Tag < ActiveRecord::Base
  if ActiveRecord.respond_to?(:version) # Rails 4+
    has_and_belongs_to_many :albums, proc{order('id DESC')}
  else
    has_and_belongs_to_many :albums, :order=>'id DESC'
  end
end

class Producer < ActiveRecord::Base; end

class Album < ActiveRecord::Base
  belongs_to :artist
  has_and_belongs_to_many :tags, :class_name=>'Name::Tag'
end

class SelfRef < ActiveRecord::Base
  belongs_to :self_ref
  has_many :self_refs
end

class Account < ActiveRecord::Base
  has_many :addresses, :as => :addressable
end

class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  validates :street, presence: true
end

module ClassMap; end
class ClassMap::CmArtist < ActiveRecord::Base
  self.table_name = "artists"
  has_many :albums, :class_name=>'ClassMap::CmAlbum', :foreign_key=>:artist_id
end
class ClassMap::CmAlbum < ActiveRecord::Base
  self.table_name = "albums"
  belongs_to :artist, :class_name=>'ClassMap::CmArtist', :foreign_key=>:artist_id
end
class ClassMap::MCArtist < ActiveRecord::Base
  self.table_name = "artists"
  has_many :albums, :class_name=>'ClassMap::MCAlbum', :foreign_key=>:artist_id
end
class ClassMap::MCAlbum < ActiveRecord::Base
  self.table_name = "albums"
  belongs_to :artist, :class_name=>'ClassMap::MCArtist', :foreign_key=>:artist_id
end
