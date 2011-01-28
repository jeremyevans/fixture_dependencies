class Artist < Sequel::Model
  one_to_many :albums
end

class Album < Sequel::Model
  many_to_one :artist
  many_to_many :tags
end

class Tag < Sequel::Model
  many_to_many :albums
end

class SelfRef < Sequel::Model
  many_to_one :self_ref
  one_to_many :self_refs
end

class ComArtist < Sequel::Model
  one_to_many :com_albums, :key=>[:artist_id1, :artist_id2]
end

class ComAlbum < Sequel::Model
  many_to_one :com_artist, :key=>[:artist_id1, :artist_id2]
  many_to_many :com_tags, :left_key=>[:album_id1, :album_id2], :right_key=>[:tag_id1, :tag_id2]
end

class ComTag < Sequel::Model
  many_to_many :com_albums, :right_key=>[:album_id1, :album_id2], :left_key=>[:tag_id1, :tag_id2]
end

