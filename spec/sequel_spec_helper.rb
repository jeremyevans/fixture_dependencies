require 'sequel'

DB = Sequel.connect(RUBY_ENGINE == 'jruby' ? 'jdbc:sqlite:spec/db/fd_spec.sqlite3' : 'sqlite://spec/db/fd_spec.sqlite3')

class Artist < Sequel::Model
  one_to_many :albums
end

class ArtistCustomFixture < Artist
  def self.fixture_filename
    :artists_custom_fixture_file
  end
  one_to_one :first_album, :class=>:Album, :key=>:artist_id
end

class Album < Sequel::Model
  many_to_one :artist
  many_to_many :tags, :class => "Name::Tag"
end

module Name; end
class Name::Tag < Sequel::Model
  many_to_many :albums, :order=>Sequel.desc(:id), :class => Album
end

class SelfRef < Sequel::Model
  many_to_one :self_ref
  one_to_many :self_refs
end

class ComArtist < Sequel::Model
  one_to_many :albums, :key=>[:artist_id1, :artist_id2], :class=>:ComAlbum
end

class ComAlbum < Sequel::Model
  many_to_one :artist, :key=>[:artist_id1, :artist_id2], :class=>:ComArtist
  many_to_many :tags, :left_key=>[:album_id1, :album_id2], :right_key=>[:tag_id1, :tag_id2], :class=>:ComTag
end

class ComTag < Sequel::Model
  many_to_many :albums, :right_key=>[:album_id1, :album_id2], :left_key=>[:tag_id1, :tag_id2], :class=>:ComAlbum
end

class ComSelfRef < Sequel::Model
  many_to_one :self_ref, :key=>[:self_ref_id1, :self_ref_id2], :class=>self
  one_to_many :self_refs, :key=>[:self_ref_id1, :self_ref_id2], :class=>self
end

class Sti < Sequel::Model
  plugin :single_table_inheritance, :kind
end

class StiSub < Sti
end

class Sty < Sequel::Model(:stis)
  plugin :single_table_inheritance, :kind, :model_map=>{nil=>:StySub, 'StiSub'=>:StySub, 'Sti'=>self}, :key_map=>{self=>'Sti', :StySub=>'StiSub'}
end

class StySub < Sty
end

class Cti < Sequel::Model
  plugin :class_table_inheritance, :key => :kind, :alias=>:ctis
end

class CtiSub < Cti
end

class CtiMm < Sequel::Model
  plugin :class_table_inheritance, :key=>:kind_id, :model_map=>{nil=>:CtiMmSub, 1=>:CtiMmSub, 2=>self}, :key_map=>{self=>2, :CtiMmSub=>1}, :alias=>:cti_mms
end

class CtiMmSub < CtiMm
end

module ClassMap; end
class ClassMap::CmArtist < Sequel::Model(:artists)
  one_to_many :albums, :class => "ClassMap::CmAlbum", :key => :artist_id
end
class ClassMap::CmAlbum < Sequel::Model(:albums)
  many_to_one :artist, :class => "ClassMap::CmArtist", :key => :artist_id
end

begin
  begin
    require 'sequel/plugins/polymorphic'
  rescue LoadError
    # old versions
    require 'sequel_polymorphic'
  end
rescue LoadError
  puts "Gem 'sequel_polymorphic' was not found. Sequel polymorphic specs will be ignored"
else
  class Account < Sequel::Model
    plugin :polymorphic
    one_to_many :addresses, :as => :addressable
  end

  class Artist < Sequel::Model
    plugin :polymorphic
    one_to_many :addresses, :as => :addressable
  end

  class Address < Sequel::Model
    plugin :polymorphic
    many_to_one :addressable, :polymorphic => true
  end
end
