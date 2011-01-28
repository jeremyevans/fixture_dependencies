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
