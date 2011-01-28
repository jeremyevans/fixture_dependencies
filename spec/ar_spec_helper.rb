require 'active_record'

ActiveRecord::Base.establish_connection(:adapter=>'sqlite3', :database=>File.join(File.dirname(File.expand_path(__FILE__)), 'db', 'fd_spec.sqlite3'))

class Artist < ActiveRecord::Base
  has_many :albums
end

class Album < ActiveRecord::Base
  belongs_to :artist
  has_and_belongs_to_many :tags
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :albums
end

class SelfRef < ActiveRecord::Base
  belongs_to :self_ref
  has_many :self_refs
end
