require_relative 'spec_helper'

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/global_expectations/autorun'

Foo = Class.new(defined?(Sequel::Model) ? Sequel::Model : ActiveRecord::Base)
def Foo.table_name; :foos end
class Bar; def self.table_name() :bars end end

verbose_modes = defined?(Sequel::Model) ? [true, false] : [false]
verbose_modes.each do |verbose|
describe FixtureDependencies do
  def load(*a) FixtureDependencies.load(*a) end
  def load_attributes(*a) FixtureDependencies.load_attributes(*a) end

  if ENV['FD_AR']
    def clear_tables
      [:ctis, :cti_subs, :cti_mms, :cti_mm_subs, :stis, :com_self_refs, :com_albums_com_tags, :com_tags, :com_albums, :com_artists, :self_refs, :albums_tags, :tags, :albums, :artists, :accounts, :addresses, :producers].each{|x| ActiveRecord::Base.connection.execute "DELETE FROM #{x}"}
    end
  else
    def clear_tables
      [:ctis, :cti_subs, :cti_mms, :cti_mm_subs, :stis, :com_self_refs, :com_albums_com_tags, :com_tags, :com_albums, :com_artists, :self_refs, :albums_tags, :tags, :albums, :artists, :accounts, :addresses, :producers].each{|x| DB[x].delete}
    end
  end

  if verbose
    def check_output(msgs)
      output = @output.dup
      output.map!{|x| x.gsub(/:0x[0-9a-f]+/, '')}
      if RUBY_VERSION >= '3.4'
        output.map!{|x| x.gsub(/:([a-z0-9_]+)=>/, '\1: ')}
        msgs = msgs.map{|x| x.gsub(/:([a-z0-9_]+)=>/, '\1: ')}
      end
      @output.clear
      output.must_equal msgs
    end

    before do
      FixtureDependencies.verbose = 3
      output = @output = []
      FixtureDependencies.define_singleton_method(:puts) do |msg|
        output << msg
      end
    end
  else
    def check_output(msgs); end
  end

  after do
    # Clear tables and fixture_dependencies caches
    clear_tables
    FixtureDependencies.loaded.clear
    FixtureDependencies.fixtures.clear
    if verbose
      FixtureDependencies.verbose = 0
      FixtureDependencies.singleton_class.send(:remove_method, :puts)
      @output.must_be_empty
    end
  end

  it "should load single records with underscore syntax" do
    ym = load(:artist__ym)
    ym.id.must_equal 1
    ym.name.must_equal 'YM'
    check_output [
      "using artist__ym",
      "load stack:[]",
      "loading artists.yml",
      "artist__ym.id = 1",
      "artist__ym.name = \"YM\"",
      "saving artist__ym"
    ]
  end

  it "should load attributes for single records with underscore syntax" do
    lym = load_attributes(:artist__lym)
    lym.name.must_equal 'LYM'
    lym.id.must_equal 4
    check_output [
      "using artist__lym",
      "load stack:[]",
      "loading artists.yml",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\""
    ]
  end

  it "should load attributes for single records with overridden values" do
    lym = FixtureDependencies.build(:artist__lym, :name=>'AAC')
    lym.name.must_equal 'AAC'
    lym.id.must_equal 4
    check_output [
      "using artist__lym",
      "load stack:[]",
      "loading artists.yml",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\""
    ]
  end

  it "should load multiple records with underscore syntax and multiple arguments" do
    rf, mo = load(:album__rf, :album__mo) 
    rf.id.must_equal 1
    rf.name.must_equal 'RF'
    mo.id.must_equal 2
    mo.name.must_equal 'MO'
    check_output [
      "using album__rf",
      "load stack:[]",
      "loading albums.yml",
      "album__rf.id = 1",
      "album__rf.name = \"RF\"",
      "album__rf.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__rf]",
      " loading artists.yml",
      " artist__ym.id = 1",
      " artist__ym.name = \"YM\"",
      " saving artist__ym",
      "album__rf.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__rf",
      "using album__mo",
      "load stack:[]",
      "album__mo.id = 2",
      "album__mo.name = \"MO\"",
      "album__mo.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__mo]",
      " using artist__ym: already in database (pk: 1)",
      "album__mo.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__mo"
    ]
  end

  it "should load attributes for multiple records with underscore syntax and multiple arguments" do
    lym, lnu = load_attributes(:artist__lym, :artist__lnu)
    lym.name.must_equal 'LYM'
    lym.id.must_equal 4
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal 5
    check_output [
      "using artist__lym",
      "load stack:[]",
      "loading artists.yml",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\"",
      "using artist__lnu",
      "load stack:[]",
      "artist__lnu.id = 5",
      "artist__lnu.name = \"LNU\""
    ] 
  end

  it "should load multiple records with hash syntax" do
    rf, mo = load(:albums=>[:rf, :mo]) 
    rf.id.must_equal 1
    rf.name.must_equal 'RF'
    mo.id.must_equal 2
    mo.name.must_equal 'MO'
    check_output [
      "using album__rf",
      "load stack:[]",
      "loading albums.yml",
      "album__rf.id = 1",
      "album__rf.name = \"RF\"",
      "album__rf.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__rf]",
      " loading artists.yml",
      " artist__ym.id = 1",
      " artist__ym.name = \"YM\"",
      " saving artist__ym",
      "album__rf.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__rf",
      "using album__mo",
      "load stack:[]",
      "album__mo.id = 2",
      "album__mo.name = \"MO\"",
      "album__mo.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__mo]",
      " using artist__ym: already in database (pk: 1)",
      "album__mo.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__mo"
    ]
  end

  it "should load attributes for multiple records with hash syntax" do
    lym, lnu = load_attributes(:artists=>[:lym, :lnu])
    lym.name.must_equal 'LYM'
    lym.id.must_equal 4
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal 5
    check_output [
      "using artist__lym",
      "load stack:[]",
      "loading artists.yml",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\"",
      "using artist__lnu",
      "load stack:[]",
      "artist__lnu.id = 5",
      "artist__lnu.name = \"LNU\""
    ]
  end

  it "should load multiple records with a mix a hashes and symbols" do
    rf, mo = load(:album__rf, :albums=>[:mo]) 
    rf.id.must_equal 1
    rf.name.must_equal 'RF'
    mo.id.must_equal 2
    mo.name.must_equal 'MO'
    check_output [
      "using album__rf",
      "load stack:[]",
      "loading albums.yml",
      "album__rf.id = 1",
      "album__rf.name = \"RF\"",
      "album__rf.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__rf]",
      " loading artists.yml",
      " artist__ym.id = 1",
      " artist__ym.name = \"YM\"",
      " saving artist__ym",
      "album__rf.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__rf",
      "using album__mo",
      "load stack:[]",
      "album__mo.id = 2",
      "album__mo.name = \"MO\"",
      "album__mo.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__mo]",
      " using artist__ym: already in database (pk: 1)",
      "album__mo.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__mo"
    ]
  end

  it "should load attributes for multiple records with a mix a hashes and symbols" do
    lym, lnu = load_attributes(:artist__lym, :artists=>[:lnu])
    lym.name.must_equal 'LYM'
    lym.id.must_equal 4
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal 5
    check_output [
      "using artist__lym",
      "load stack:[]",
      "loading artists.yml",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\"",
      "using artist__lnu",
      "load stack:[]",
      "artist__lnu.id = 5",
      "artist__lnu.name = \"LNU\""
    ]
  end

  it "should load whole tables at once with single symbol" do
    Artist.count.must_equal 0
    load(:artists) 
    Artist.count.must_equal 5
    check_output [
      "loading artist.yml",
      "using artist__ym",
      "load stack:[]",
      "artist__ym.id = 1",
      "artist__ym.name = \"YM\"",
      "saving artist__ym",
      "using artist__nu",
      "load stack:[]",
      "artist__nu.id = 2",
      "artist__nu.name = \"NU\"",
      "saving artist__nu",
      "artist__nu.albums: one_to_many:album__p",
      "using album__p",
      "load stack:[]",
      "loading albums.yml",
      "album__p.id = 3",
      "album__p.name = \"P\"",
      "album__p.artist: belongs_to:artist__nu",
      " using artist__nu",
      " load stack:[:album__p]",
      " using artist__nu: already in database (pk: 2)",
      "album__p.artist = #<Artist @values={:id=>2, :name=>\"NU\"}>",
      "saving album__p",
      "using artist__lym",
      "load stack:[]",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\"",
      "saving artist__lym",
      "using artist__lnu",
      "load stack:[]",
      "artist__lnu.id = 5",
      "artist__lnu.name = \"LNU\"",
      "saving artist__lnu",
      "using artist__map",
      "load stack:[]",
      "artist__map.id = 3",
      "artist__map.name = \"MAP\"",
      "saving artist__map",
      "artist__map.albums: one_to_many:album__cm",
      "using album__cm",
      "load stack:[]",
      "album__cm.id = 5",
      "album__cm.name = \"CM\"",
      "album__cm.artist: belongs_to:artist__map",
      " using artist__map",
      " load stack:[:album__cm]",
      " using artist__map: already in database (pk: 3)",
      "album__cm.artist = #<Artist @values={:id=>3, :name=>\"MAP\"}>",
      "saving album__cm"
    ]
  end

  it "should load attributes for whole tables at once with single symbol" do
    lnu, lym, map, nu, ym = load_attributes(:artists).sort_by{|x| x.name}
    ym.name.must_equal 'YM'
    ym.id.must_equal 1
    nu.name.must_equal 'NU'
    nu.id.must_equal 2
    lym.name.must_equal 'LYM'
    lym.id.must_equal 4
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal 5
    map.name.must_equal 'MAP'
    map.id.must_equal 3
    check_output [
      "loading artist.yml",
      "using artist__ym",
      "load stack:[]",
      "artist__ym.id = 1",
      "artist__ym.name = \"YM\"",
      "using artist__nu",
      "load stack:[]",
      "artist__nu.id = 2",
      "artist__nu.name = \"NU\"",
      "using artist__lym",
      "load stack:[]",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\"",
      "using artist__lnu",
      "load stack:[]",
      "artist__lnu.id = 5",
      "artist__lnu.name = \"LNU\"",
      "using artist__map",
      "load stack:[]",
      "artist__map.id = 3",
      "artist__map.name = \"MAP\""
    ]
  end

  it "should load multiple whole tables at once with a symbol for each" do
    Artist.count.must_equal 0
    Album.count.must_equal 0
    load(:artists, :albums) 
    Artist.count.must_equal 5
    Album.count.must_equal 5
    check_output [
      "loading artist.yml",
      "using artist__ym",
      "load stack:[]",
      "artist__ym.id = 1",
      "artist__ym.name = \"YM\"",
      "saving artist__ym",
      "using artist__nu",
      "load stack:[]",
      "artist__nu.id = 2",
      "artist__nu.name = \"NU\"",
      "saving artist__nu",
      "artist__nu.albums: one_to_many:album__p",
      "using album__p",
      "load stack:[]",
      "loading albums.yml",
      "album__p.id = 3",
      "album__p.name = \"P\"",
      "album__p.artist: belongs_to:artist__nu",
      " using artist__nu",
      " load stack:[:album__p]",
      " using artist__nu: already in database (pk: 2)",
      "album__p.artist = #<Artist @values={:id=>2, :name=>\"NU\"}>",
      "saving album__p",
      "using artist__lym",
      "load stack:[]",
      "artist__lym.id = 4",
      "artist__lym.name = \"LYM\"",
      "saving artist__lym",
      "using artist__lnu",
      "load stack:[]",
      "artist__lnu.id = 5",
      "artist__lnu.name = \"LNU\"",
      "saving artist__lnu",
      "using artist__map",
      "load stack:[]",
      "artist__map.id = 3",
      "artist__map.name = \"MAP\"",
      "saving artist__map",
      "artist__map.albums: one_to_many:album__cm",
      "using album__cm",
      "load stack:[]",
      "album__cm.id = 5",
      "album__cm.name = \"CM\"",
      "album__cm.artist: belongs_to:artist__map",
      " using artist__map",
      " load stack:[:album__cm]",
      " using artist__map: already in database (pk: 3)",
      "album__cm.artist = #<Artist @values={:id=>3, :name=>\"MAP\"}>",
      "saving album__cm",
      "using album__rf",
      "load stack:[]",
      "album__rf.id = 1",
      "album__rf.name = \"RF\"",
      "album__rf.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__rf]",
      " using artist__ym: already in database (pk: 1)",
      "album__rf.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__rf",
      "using album__mo",
      "load stack:[]",
      "album__mo.id = 2",
      "album__mo.name = \"MO\"",
      "album__mo.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__mo]",
      " using artist__ym: already in database (pk: 1)",
      "album__mo.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__mo",
      "using album__p",
      "load stack:[]",
      "using album__p: already in database (pk: 3)",
      "using album__q",
      "load stack:[]",
      "album__q.id = 4",
      "album__q.name = \"Q\"",
      "album__q.artist: belongs_to:artist__lnu",
      " using artist__lnu",
      " load stack:[:album__q]",
      " using artist__lnu: already in database (pk: 5)",
      "album__q.artist = #<Artist @values={:id=>5, :name=>\"LNU\"}>",
      "saving album__q",
      "using album__cm",
      "load stack:[]",
      "using album__cm: already in database (pk: 5)"
    ]
  end

  it "should load associated many_to_one records" do
    rf = load(:album__rf)
    rf.artist.id.must_equal 1
    check_output [
      "using album__rf",
      "load stack:[]",
      "loading albums.yml",
      "album__rf.id = 1",
      "album__rf.name = \"RF\"",
      "album__rf.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__rf]",
      " loading artists.yml",
      " artist__ym.id = 1",
      " artist__ym.name = \"YM\"",
      " saving artist__ym",
      "album__rf.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__rf"
    ]
  end

  it "should load associated one_to_many records" do
    nu = load(:artist__nu)
    nu.albums.length.must_equal 1
    nu.albums.first.id.must_equal 3
    nu.albums.first.name.must_equal 'P'
    check_output [
      "using artist__nu",
      "load stack:[]",
      "loading artists.yml",
      "artist__nu.id = 2",
      "artist__nu.name = \"NU\"",
      "saving artist__nu",
      "artist__nu.albums: one_to_many:album__p",
      "using album__p",
      "load stack:[]",
      "loading albums.yml",
      "album__p.id = 3",
      "album__p.name = \"P\"",
      "album__p.artist: belongs_to:artist__nu",
      " using artist__nu",
      " load stack:[:album__p]",
      " using artist__nu: already in database (pk: 2)",
      "album__p.artist = #<Artist @values={:id=>2, :name=>\"NU\"}>",
      "saving album__p"
    ]
  end

  it "should load associated many_to_one record when loading attributes" do
    q = load_attributes(:album__q)
    q.id.must_equal 4
    q.name.must_equal 'Q'
    q.artist.name.must_equal 'LNU'
    check_output [
      "using album__q",
      "load stack:[]",
      "loading albums.yml",
      "album__q.id = 4",
      "album__q.name = \"Q\"",
      "album__q.artist: belongs_to:artist__lnu",
      " using artist__lnu",
      " load stack:[:album__q]",
      " loading artists.yml",
      " artist__lnu.id = 5",
      " artist__lnu.name = \"LNU\"",
      " saving artist__lnu",
      "album__q.artist = #<Artist @values={:id=>5, :name=>\"LNU\"}>"
    ]
  end

  it "should load associated many_to_many records and handle cycles (I->P->NU->P)" do
    i = load(:tag__i)
    i.albums.length.must_equal 2
    p = i.albums.first
    p.id.must_equal 3
    p.name.must_equal 'P'
    mo = i.albums.last
    mo.id.must_equal 2
    mo.name.must_equal 'MO'
    nu = p.artist
    nu.id.must_equal 2
    nu.name.must_equal 'NU'
    nu.albums.length.must_equal 1
    nu.albums.first.must_equal p
    check_output [
      "using tag__i",
      "load stack:[]",
      "loading tags.yml",
      "tag__i.id = 2",
      "tag__i.name = \"I\"",
      "saving tag__i",
      "tag__i.albums: many_to_many:album__p",
      "using album__p",
      "load stack:[]",
      "loading albums.yml",
      "album__p.id = 3",
      "album__p.name = \"P\"",
      "album__p.artist: belongs_to:artist__nu",
      " using artist__nu",
      " load stack:[:album__p]",
      " loading artists.yml",
      " artist__nu.id = 2",
      " artist__nu.name = \"NU\"",
      " saving artist__nu",
      " artist__nu.albums: one_to_many cycle detected:album__p",
      "album__p.artist = #<Artist @values={:id=>2, :name=>\"NU\"}>",
      "saving album__p",
      "tag__i.albums: many_to_many:album__mo",
      "using album__mo",
      "load stack:[]",
      "album__mo.id = 2",
      "album__mo.name = \"MO\"",
      "album__mo.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__mo]",
      " artist__ym.id = 1",
      " artist__ym.name = \"YM\"",
      " saving artist__ym",
      "album__mo.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__mo"
    ]
  end

  it "should not load records that were not asked for" do
    ym = load(:artist__ym) 
    Artist.count.must_equal 1
    Artist.first.must_equal ym
    load(:artist__nu)
    Artist.count.must_equal 2
    check_output [
      "using artist__ym",
      "load stack:[]",
      "loading artists.yml",
      "artist__ym.id = 1",
      "artist__ym.name = \"YM\"",
      "saving artist__ym",
      "using artist__nu",
      "load stack:[]",
      "artist__nu.id = 2",
      "artist__nu.name = \"NU\"",
      "saving artist__nu",
      "artist__nu.albums: one_to_many:album__p",
      "using album__p",
      "load stack:[]",
      "loading albums.yml",
      "album__p.id = 3",
      "album__p.name = \"P\"",
      "album__p.artist: belongs_to:artist__nu",
      " using artist__nu",
      " load stack:[:album__p]",
      " using artist__nu: already in database (pk: 2)",
      "album__p.artist = #<Artist @values={:id=>2, :name=>\"NU\"}>",
      "saving album__p"
    ]
  end

  it "should handle self referential records" do
    i = load(:self_ref__i)
    i.id.must_equal 1
    i.self_ref.id.must_equal 1
    i.self_refs.length.must_equal 1
    i.self_refs.first.id.must_equal 1
    check_output [
      "using self_ref__i",
      "load stack:[]",
      "loading self_refs.yml",
      "self_ref__i.id = 1",
      "self_ref__i.self_ref: belongs_to self-referential",
      "self_ref__i.self_ref_id = 1",
      "saving self_ref__i",
      "self_ref__i.self_refs: one_to_many self-referential"
    ]
  end

  it "should handle association cycles" do
    a = load(:self_ref__a)
    a.id.must_equal 2
    b = a.self_ref
    b.id.must_equal 3
    c = b.self_ref
    c.id.must_equal 4
    c.self_ref.must_equal a
    check_output [
      "using self_ref__a",
      "load stack:[]",
      "loading self_refs.yml",
      "self_ref__a.id = 2",
      "self_ref__a.self_ref: belongs_to:self_ref__b",
      " using self_ref__b",
      " load stack:[:self_ref__a]",
      " self_ref__b.id = 3",
      " self_ref__b.self_ref: belongs_to:self_ref__c",
      "  using self_ref__c",
      "  load stack:[:self_ref__a, :self_ref__b]",
      "  self_ref__c.id = 4",
      "  self_ref__c.self_ref: belongs-to cycle detected:self_ref__a",
      "  self_ref__c.self_ref = nil",
      "  saving self_ref__c",
      " self_ref__b.self_ref = #<SelfRef @values={:id=>4, :self_ref_id=>nil}>",
      " saving self_ref__b",
      "self_ref__a.self_ref = #<SelfRef @values={:id=>3, :self_ref_id=>4}>",
      "saving self_ref__a"
    ]
  end

  it "should raise error nonexistent fixture files" do
    proc{load(:foos)}.must_raise(ArgumentError)
    check_output [
      "loading foo.yml"
    ]
  end

  it "should raise error for unsupported model classes" do
    proc{load(:bars)}.must_raise(TypeError)
    check_output [
      "loading bar.yml",
      "using bar__i",
      "load stack:[]"
    ]
  end

  it "should handle cyclic dependencies in classmap when camelized name matches" do
    cm = load(:cm_album__cm)
    cm.name.must_equal "CM"
    check_output [
      "using cm_album__cm",
      "load stack:[]",
      "loading albums.yml",
      "cm_album__cm.id = 5",
      "cm_album__cm.name = \"CM\"",
      "cm_album__cm.artist: belongs_to:cm_artist__map",
      " using cm_artist__map",
      " load stack:[:cm_album__cm]",
      " loading artists.yml",
      " cm_artist__map.id = 3",
      " cm_artist__map.name = \"MAP\"",
      " saving cm_artist__map",
      " cm_artist__map.albums: one_to_many cycle detected:cm_album__cm",
      "cm_album__cm.artist = #<ClassMap::CmArtist @values={:id=>3, :name=>\"MAP\"}>",
      "saving cm_album__cm"
    ]
  end

  it "should handle cyclic dependencies in classmap when camelized name does not match" do
    cm = load(:mc_album__cm)
    cm.name.must_equal "CM"
    check_output [
      "using mc_album__cm",
      "load stack:[]",
      "loading albums.yml",
      "mc_album__cm.id = 5",
      "mc_album__cm.name = \"CM\"",
      "mc_album__cm.artist: belongs_to:mc_artist__map",
      " using mc_artist__map",
      " load stack:[:mc_album__cm]",
      " loading artists.yml",
      " mc_artist__map.id = 3",
      " mc_artist__map.name = \"MAP\"",
      " saving mc_artist__map",
      " mc_artist__map.albums: one_to_many cycle detected:mc_album__cm",
      "mc_album__cm.artist = #<ClassMap::MCArtist @values={:id=>3, :name=>\"MAP\"}>",
      "saving mc_album__cm"
    ]
  end

  if defined?(Account) && defined?(Address)
    it "should handle normal fixture correctly" do
      account = load(:account__john)
      account.name.must_equal "John Smith"
      check_output [
        "using account__john",
        "load stack:[]",
        "loading accounts.yml",
        "account__john.id = 1",
        "account__john.name = \"John Smith\"",
        "saving account__john"
      ]
    end

    it "should handle polymorphic one_to_many correctly" do
      account = load(:account__john)
      account.name.must_equal "John Smith"

      address = load(:address__john_address)
      address.street.must_equal "743 Evergreen Boulevard"

      account.addresses.must_equal [address]
      check_output [
        "using account__john",
        "load stack:[]",
        "loading accounts.yml",
        "account__john.id = 1",
        "account__john.name = \"John Smith\"",
        "saving account__john",
        "using address__john_address",
        "load stack:[]",
        "loading addresses.yml",
        "address__john_address.addressable: belongs_to:account__john",
        " using account__john",
        " load stack:[:address__john_address]",
        " using account__john: already in database (pk: 1)",
        "address__john_address.addressable = #<Account @values={:id=>1, :name=>\"John Smith\"}>",
        "address__john_address.street = \"743 Evergreen Boulevard\"",
        "address__john_address.city = \"Springfield\"",
        "saving address__john_address"
      ]
    end

    it "should handle polymorphic many_to_one correctly" do
      address = load(:address__john_address)
      address.street.must_equal "743 Evergreen Boulevard"

      account = address.addressable
      account.name.must_equal "John Smith"
      check_output [
        "using address__john_address",
        "load stack:[]",
        "loading addresses.yml",
        "address__john_address.addressable: belongs_to:account__john",
        " using account__john",
        " load stack:[:address__john_address]",
        " loading accounts.yml",
        " account__john.id = 1",
        " account__john.name = \"John Smith\"",
        " saving account__john",
        "address__john_address.addressable = #<Account @values={:id=>1, :name=>\"John Smith\"}>",
        "address__john_address.street = \"743 Evergreen Boulevard\"",
        "address__john_address.city = \"Springfield\"",
        "saving address__john_address"
      ]
    end

    it "should handle more than 1 polymorphic correctly" do
      address = load(:address__lym_address)
      address.street.must_equal "123 Walnut Street - Moe's Tavern"

      artist = address.addressable
      artist.name.must_equal "LYM"
      check_output [
        "using address__lym_address",
        "load stack:[]",
        "loading addresses.yml",
        "address__lym_address.addressable: belongs_to:artist__lym",
        " using artist__lym",
        " load stack:[:address__lym_address]",
        " loading artists.yml",
        " artist__lym.id = 4",
        " artist__lym.name = \"LYM\"",
        " saving artist__lym",
        "address__lym_address.addressable = #<Artist @values={:id=>4, :name=>\"LYM\"}>",
        "address__lym_address.street = \"123 Walnut Street - Moe's Tavern\"",
        "address__lym_address.city = \"Springfield\"",
        "saving address__lym_address"
      ]
    end

    it "should raise error with better message" do
      err = proc { load(:address__invalid_address) }.must_raise(ActiveRecord::RecordInvalid)
      err.message.must_match "Validation failed: Street can't be blank"
      check_output [
      ]
    end if defined?(ActiveRecord::RecordInvalid)
  end

  unless ENV['FD_AR']
    it "should load single records with underscore syntax with composite keys" do
      ym = load(:com_artist__ym)
      ym.id1.must_equal 1
      ym.id2.must_equal 2
      ym.name.must_equal 'YM'
      check_output [
        "using com_artist__ym",
        "load stack:[]",
        "loading com_artists.yml",
        "com_artist__ym.id1 = 1",
        "com_artist__ym.id2 = 2",
        "com_artist__ym.name = \"YM\"",
        "saving com_artist__ym"
      ]
    end

    it "should load multiple records with underscore syntax and multiple arguments with composite keys" do
      rf, mo = load(:com_album__rf, :com_album__mo) 
      rf.id1.must_equal 1
      rf.id2.must_equal 2
      rf.name.must_equal 'RF'
      mo.id1.must_equal 3
      mo.id2.must_equal 4
      mo.name.must_equal 'MO'
      check_output [
        "using com_album__rf",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__rf.id1 = 1",
        "com_album__rf.id2 = 2",
        "com_album__rf.name = \"RF\"",
        "com_album__rf.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__rf]",
        " loading com_artists.yml",
        " com_artist__ym.id1 = 1",
        " com_artist__ym.id2 = 2",
        " com_artist__ym.name = \"YM\"",
        " saving com_artist__ym",
        "com_album__rf.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__rf",
        "using com_album__mo",
        "load stack:[]",
        "com_album__mo.id1 = 3",
        "com_album__mo.id2 = 4",
        "com_album__mo.name = \"MO\"",
        "com_album__mo.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__mo]",
        " using com_artist__ym: already in database (pk: [1, 2])",
        "com_album__mo.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__mo"
      ]
    end

    it "should load multiple records with hash syntax with composite keys" do
      rf, mo = load(:com_albums=>[:rf, :mo]) 
      rf.id1.must_equal 1
      rf.id2.must_equal 2
      rf.name.must_equal 'RF'
      mo.id1.must_equal 3
      mo.id2.must_equal 4
      mo.name.must_equal 'MO'
      check_output [
        "using com_album__rf",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__rf.id1 = 1",
        "com_album__rf.id2 = 2",
        "com_album__rf.name = \"RF\"",
        "com_album__rf.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__rf]",
        " loading com_artists.yml",
        " com_artist__ym.id1 = 1",
        " com_artist__ym.id2 = 2",
        " com_artist__ym.name = \"YM\"",
        " saving com_artist__ym",
        "com_album__rf.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__rf",
        "using com_album__mo",
        "load stack:[]",
        "com_album__mo.id1 = 3",
        "com_album__mo.id2 = 4",
        "com_album__mo.name = \"MO\"",
        "com_album__mo.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__mo]",
        " using com_artist__ym: already in database (pk: [1, 2])",
        "com_album__mo.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__mo"
      ]
    end

    it "should load multiple records with a mix a hashes and symbols with composite keys" do
      rf, mo = load(:com_album__rf, :com_albums=>[:mo]) 
      rf.id1.must_equal 1
      rf.id2.must_equal 2
      rf.name.must_equal 'RF'
      mo.id1.must_equal 3
      mo.id2.must_equal 4
      mo.name.must_equal 'MO'
      check_output [
        "using com_album__rf",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__rf.id1 = 1",
        "com_album__rf.id2 = 2",
        "com_album__rf.name = \"RF\"",
        "com_album__rf.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__rf]",
        " loading com_artists.yml",
        " com_artist__ym.id1 = 1",
        " com_artist__ym.id2 = 2",
        " com_artist__ym.name = \"YM\"",
        " saving com_artist__ym",
        "com_album__rf.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__rf",
        "using com_album__mo",
        "load stack:[]",
        "com_album__mo.id1 = 3",
        "com_album__mo.id2 = 4",
        "com_album__mo.name = \"MO\"",
        "com_album__mo.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__mo]",
        " using com_artist__ym: already in database (pk: [1, 2])",
        "com_album__mo.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__mo"
      ]
    end

    it "should load whole tables at once with single symbol with composite keys" do
      ComArtist.count.must_equal 0
      load(:com_artists) 
      ComArtist.count.must_equal 2
      check_output [
        "loading com_artist.yml",
        "using com_artist__ym",
        "load stack:[]",
        "com_artist__ym.id1 = 1",
        "com_artist__ym.id2 = 2",
        "com_artist__ym.name = \"YM\"",
        "saving com_artist__ym",
        "using com_artist__nu",
        "load stack:[]",
        "com_artist__nu.id1 = 3",
        "com_artist__nu.id2 = 4",
        "com_artist__nu.name = \"NU\"",
        "saving com_artist__nu",
        "com_artist__nu.albums: one_to_many:com_album__p",
        "using com_album__p",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__p.id1 = 5",
        "com_album__p.id2 = 6",
        "com_album__p.name = \"P\"",
        "com_album__p.artist: belongs_to:com_artist__nu",
        " using com_artist__nu",
        " load stack:[:com_album__p]",
        " using com_artist__nu: already in database (pk: [3, 4])",
        "com_album__p.artist = #<ComArtist @values={:id1=>3, :id2=>4, :name=>\"NU\"}>",
        "saving com_album__p"
      ]
    end

    it "should load whole tables at once with single symbol with composite keys" do
      ComArtist.count.must_equal 0
      ComAlbum.count.must_equal 0
      load(:com_artists, :com_albums) 
      ComArtist.count.must_equal 2
      ComAlbum.count.must_equal 3
      check_output [
        "loading com_artist.yml",
        "using com_artist__ym",
        "load stack:[]",
        "com_artist__ym.id1 = 1",
        "com_artist__ym.id2 = 2",
        "com_artist__ym.name = \"YM\"",
        "saving com_artist__ym",
        "using com_artist__nu",
        "load stack:[]",
        "com_artist__nu.id1 = 3",
        "com_artist__nu.id2 = 4",
        "com_artist__nu.name = \"NU\"",
        "saving com_artist__nu",
        "com_artist__nu.albums: one_to_many:com_album__p",
        "using com_album__p",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__p.id1 = 5",
        "com_album__p.id2 = 6",
        "com_album__p.name = \"P\"",
        "com_album__p.artist: belongs_to:com_artist__nu",
        " using com_artist__nu",
        " load stack:[:com_album__p]",
        " using com_artist__nu: already in database (pk: [3, 4])",
        "com_album__p.artist = #<ComArtist @values={:id1=>3, :id2=>4, :name=>\"NU\"}>",
        "saving com_album__p",
        "using com_album__rf",
        "load stack:[]",
        "com_album__rf.id1 = 1",
        "com_album__rf.id2 = 2",
        "com_album__rf.name = \"RF\"",
        "com_album__rf.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__rf]",
        " using com_artist__ym: already in database (pk: [1, 2])",
        "com_album__rf.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__rf",
        "using com_album__mo",
        "load stack:[]",
        "com_album__mo.id1 = 3",
        "com_album__mo.id2 = 4",
        "com_album__mo.name = \"MO\"",
        "com_album__mo.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__mo]",
        " using com_artist__ym: already in database (pk: [1, 2])",
        "com_album__mo.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__mo",
        "using com_album__p",
        "load stack:[]",
        "using com_album__p: already in database (pk: [5, 6])"
      ]
    end

    it "should load associated many_to_one records with composite keys" do
      rf = load(:com_album__rf)
      rf.artist.id1.must_equal 1
      rf.artist.id2.must_equal 2
      check_output [
        "using com_album__rf",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__rf.id1 = 1",
        "com_album__rf.id2 = 2",
        "com_album__rf.name = \"RF\"",
        "com_album__rf.artist: belongs_to:com_artist__ym",
        " using com_artist__ym",
        " load stack:[:com_album__rf]",
        " loading com_artists.yml",
        " com_artist__ym.id1 = 1",
        " com_artist__ym.id2 = 2",
        " com_artist__ym.name = \"YM\"",
        " saving com_artist__ym",
        "com_album__rf.artist = #<ComArtist @values={:id1=>1, :id2=>2, :name=>\"YM\"}>",
        "saving com_album__rf"
      ]
    end

    it "should load associated one_to_many records with composite keys" do
      nu = load(:com_artist__nu)
      nu.albums.length.must_equal 1
      nu.albums.first.id1.must_equal 5
      nu.albums.first.id2.must_equal 6
      nu.albums.first.name.must_equal 'P'
      check_output [
        "using com_artist__nu",
        "load stack:[]",
        "loading com_artists.yml",
        "com_artist__nu.id1 = 3",
        "com_artist__nu.id2 = 4",
        "com_artist__nu.name = \"NU\"",
        "saving com_artist__nu",
        "com_artist__nu.albums: one_to_many:com_album__p",
        "using com_album__p",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__p.id1 = 5",
        "com_album__p.id2 = 6",
        "com_album__p.name = \"P\"",
        "com_album__p.artist: belongs_to:com_artist__nu",
        " using com_artist__nu",
        " load stack:[:com_album__p]",
        " using com_artist__nu: already in database (pk: [3, 4])",
        "com_album__p.artist = #<ComArtist @values={:id1=>3, :id2=>4, :name=>\"NU\"}>",
        "saving com_album__p"
      ]
    end

    it "should load associated many_to_many records and handle cycles (I->P->NU->P) with composite keys" do
      i = load(:com_tag__i)
      i.albums.length.must_equal 1
      p = i.albums.first
      p.id1.must_equal 5
      p.id2.must_equal 6
      p.name.must_equal 'P'
      nu = p.artist
      nu.id1.must_equal 3
      nu.id2.must_equal 4
      nu.name.must_equal 'NU'
      nu.albums.length.must_equal 1
      nu.albums.first.must_equal p
      check_output [
        "using com_tag__i",
        "load stack:[]",
        "loading com_tags.yml",
        "com_tag__i.id1 = 3",
        "com_tag__i.id2 = 4",
        "com_tag__i.name = \"I\"",
        "saving com_tag__i",
        "com_tag__i.albums: many_to_many:com_album__p",
        "using com_album__p",
        "load stack:[]",
        "loading com_albums.yml",
        "com_album__p.id1 = 5",
        "com_album__p.id2 = 6",
        "com_album__p.name = \"P\"",
        "com_album__p.artist: belongs_to:com_artist__nu",
        " using com_artist__nu",
        " load stack:[:com_album__p]",
        " loading com_artists.yml",
        " com_artist__nu.id1 = 3",
        " com_artist__nu.id2 = 4",
        " com_artist__nu.name = \"NU\"",
        " saving com_artist__nu",
        " com_artist__nu.albums: one_to_many cycle detected:com_album__p",
        "com_album__p.artist = #<ComArtist @values={:id1=>3, :id2=>4, :name=>\"NU\"}>",
        "saving com_album__p"
      ]
    end

    it "should handle self referential records with composite keys" do
      i = load(:com_self_ref__i)
      i.id1.must_equal 1
      i.id2.must_equal 2
      i.self_ref.id1.must_equal 1
      i.self_ref.id2.must_equal 2
      i.self_refs.length.must_equal 1
      i.self_refs.first.id1.must_equal 1
      i.self_refs.first.id2.must_equal 2
      check_output [
        "using com_self_ref__i",
        "load stack:[]",
        "loading com_self_refs.yml",
        "com_self_ref__i.id1 = 1",
        "com_self_ref__i.id2 = 2",
        "com_self_ref__i.self_ref: belongs_to self-referential",
        "com_self_ref__i.self_ref_id1 = 1",
        "com_self_ref__i.self_ref_id2 = 2",
        "saving com_self_ref__i",
        "com_self_ref__i.self_refs: one_to_many self-referential"
      ]
    end

    it "should composite and associated primary keys with composite keys" do
      a = load(:com_self_ref__a)
      a.id1.must_equal 3
      a.id2.must_equal 4
      b = a.self_ref
      b.id1.must_equal 5
      b.id2.must_equal 6
      c = b.self_ref
      c.id1.must_equal 7
      c.id2.must_equal 8
      c.self_ref.must_equal a
      check_output [
        "using com_self_ref__a",
        "load stack:[]",
        "loading com_self_refs.yml",
        "com_self_ref__a.id1 = 3",
        "com_self_ref__a.id2 = 4",
        "com_self_ref__a.self_ref: belongs_to:com_self_ref__b",
        " using com_self_ref__b",
        " load stack:[:com_self_ref__a]",
        " com_self_ref__b.id1 = 5",
        " com_self_ref__b.id2 = 6",
        " com_self_ref__b.self_ref: belongs_to:com_self_ref__c",
        "  using com_self_ref__c",
        "  load stack:[:com_self_ref__a, :com_self_ref__b]",
        "  com_self_ref__c.id1 = 7",
        "  com_self_ref__c.id2 = 8",
        "  com_self_ref__c.self_ref: belongs-to cycle detected:com_self_ref__a",
        "  com_self_ref__c.self_ref = nil",
        "  saving com_self_ref__c",
        " com_self_ref__b.self_ref = #<ComSelfRef @values={:id1=>7, :id2=>8, :self_ref_id1=>nil, :self_ref_id2=>nil}>",
        " saving com_self_ref__b",
        "com_self_ref__a.self_ref = #<ComSelfRef @values={:id1=>5, :id2=>6, :self_ref_id1=>7, :self_ref_id2=>8}>",
        "saving com_self_ref__a"
      ]
    end

    it "should handle CTI tables correctly" do
      main, sub, nl = load(:ctis=>[:main, :sub, :nil])
      main.class.must_equal Cti
      sub.class.must_equal CtiSub
      nl.class.must_equal Cti
      check_output [
        "using cti__main",
        "load stack:[]",
        "loading ctis.yml",
        "Cti STI plugin detected, initializing instance of #<Cti>",
        "cti__main.id = 1",
        "cti__main.kind = \"Cti\"",
        "cti__main.number = 10",
        "saving cti__main",
        "using cti__sub",
        "load stack:[]",
        "CtiSub STI plugin detected, initializing instance of #<CtiSub>",
        "cti__sub.id = 2",
        "cti__sub.kind = \"CtiSub\"",
        "cti__sub.number = 20",
        "cti__sub.extra_number = 100",
        "saving cti__sub",
        "using cti__nil",
        "load stack:[]",
        "Cti STI plugin detected, initializing instance of #<Cti>",
        "cti__nil.id = 3",
        "cti__nil.number = 30",
        "saving cti__nil"
      ]
    end

    it "should handle CTI tables with model maps correctly" do
      main, sub, nl = load(:cti_mm=>[:main, :sub, :nil])
      main.class.must_equal CtiMm
      sub.class.must_equal CtiMmSub
      nl.class.must_equal CtiMmSub
      check_output [
        "using cti_mm__main",
        "load stack:[]",
        "loading cti_mms.yml",
        "CtiMm STI plugin detected, initializing instance of #<CtiMm>",
        "cti_mm__main.id = 1",
        "cti_mm__main.kind_id = 2",
        "cti_mm__main.number = 10",
        "saving cti_mm__main",
        "using cti_mm__sub",
        "load stack:[]",
        "CtiMmSub STI plugin detected, initializing instance of #<CtiMmSub>",
        "cti_mm__sub.id = 2",
        "cti_mm__sub.kind_id = 1",
        "cti_mm__sub.number = 20",
        "cti_mm__sub.extra_number = 100",
        "saving cti_mm__sub",
        "using cti_mm__nil",
        "load stack:[]",
        "CtiMmSub STI plugin detected, initializing instance of #<CtiMmSub>",
        "cti_mm__nil.id = 3",
        "cti_mm__nil.number = 30",
        "saving cti_mm__nil"
      ]
    end

    it "should handle STI tables correctly" do
      main, sub, nl = load(:stis=>[:main, :sub, :nil])
      main.class.must_equal Sti
      sub.class.must_equal StiSub
      nl.class.must_equal Sti
      check_output [
        "using sti__main",
        "load stack:[]",
        "loading stis.yml",
        "Sti STI plugin detected, initializing instance of #<Sti>",
        "sti__main.id = 1",
        "sti__main.kind = \"Sti\"",
        "sti__main.number = 10",
        "saving sti__main",
        "using sti__sub",
        "load stack:[]",
        "StiSub STI plugin detected, initializing instance of #<StiSub>",
        "sti__sub.id = 2",
        "sti__sub.kind = \"StiSub\"",
        "sti__sub.number = 20",
        "saving sti__sub",
        "using sti__nil",
        "load stack:[]",
        "Sti STI plugin detected, initializing instance of #<Sti>",
        "sti__nil.id = 3",
        "sti__nil.number = 30",
        "saving sti__nil"
      ]
    end

    it "should handle STI tables with model maps correctly" do
      main, sub, nl = load(:stys=>[:main, :sub, :nil])
      main.class.must_equal Sty
      sub.class.must_equal StySub
      nl.class.must_equal StySub
      check_output [
        "using sty__main",
        "load stack:[]",
        "loading stis.yml",
        "Sty STI plugin detected, initializing instance of #<Sty>",
        "sty__main.id = 1",
        "sty__main.kind = \"Sti\"",
        "sty__main.number = 10",
        "saving sty__main",
        "using sty__sub",
        "load stack:[]",
        "StySub STI plugin detected, initializing instance of #<StySub>",
        "sty__sub.id = 2",
        "sty__sub.kind = \"StiSub\"",
        "sty__sub.number = 20",
        "saving sty__sub",
        "using sty__nil",
        "load stack:[]",
        "StySub STI plugin detected, initializing instance of #<StySub>",
        "sty__nil.id = 3",
        "sty__nil.number = 30",
        "saving sty__nil"
      ]
    end
  end

  it "should load associated many_to_one records" do
    rf = load(:album__rf)
    rf.artist.id.must_equal 1
    check_output [
      "using album__rf",
      "load stack:[]",
      "loading albums.yml",
      "album__rf.id = 1",
      "album__rf.name = \"RF\"",
      "album__rf.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__rf]",
      " loading artists.yml",
      " artist__ym.id = 1",
      " artist__ym.name = \"YM\"",
      " saving artist__ym",
      "album__rf.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__rf"
    ]
  end

  it "should handle models with fixture_filename defined" do
    rf = load(:artist_custom_fixture__ym)
    rf.name.must_equal "YMCUSTOM"
    check_output [
      "using artist_custom_fixture__ym",
      "load stack:[]",
      "loading artists.yml",
      "artist_custom_fixture__ym.id = 3",
      "artist_custom_fixture__ym.name = \"YMCUSTOM\"",
      "saving artist_custom_fixture__ym",
      "artist_custom_fixture__ym.first_album: one_to_one:album__rf",
      "using album__rf",
      "load stack:[]",
      "loading albums.yml",
      "album__rf.id = 1",
      "album__rf.name = \"RF\"",
      "album__rf.artist: belongs_to:artist__ym",
      " using artist__ym",
      " load stack:[:album__rf]",
      " loading artists.yml",
      " artist__ym.id = 1",
      " artist__ym.name = \"YM\"",
      " saving artist__ym",
      "album__rf.artist = #<Artist @values={:id=>1, :name=>\"YM\"}>",
      "saving album__rf"
    ]
  end

  it "should handle dates and times without quote marks" do
    begin
      FixtureDependencies.use_unsafe_load = true

      prd = load(:producer__prd)
      prd.created_at.must_be_instance_of Time
      prd.date_of_birth.must_be_instance_of Date
      check_output [
        "using producer__prd",
        "load stack:[]",
        "loading producers.yml",
        "producer__prd.id = 1",
        "producer__prd.name = \"PRD\"",
        "producer__prd.date_of_birth = #<Date: 2024-01-01 ((2460311j,0s,0n),+0s,-Infj)>",
        "producer__prd.created_at = 2021-02-16 10:00:00 -0800",
        "saving producer__prd"
      ]
    ensure
      FixtureDependencies.use_unsafe_load = false
    end
  end if YAML.respond_to?(:use_unsafe_load)

  it "should raise error for invalid fixture" do
    proc{load(:album__nonexistant)}.must_raise(defined?(Sequel::Error) ? Sequel::Error : ActiveRecord::RecordNotFound)
    check_output [
      "using album__nonexistant",
      "load stack:[]",
      "loading albums.yml"
    ]
  end

  it "should raise error if there is no fixture path" do
    begin
      fixture_path = FixtureDependencies.fixture_path
      FixtureDependencies.fixture_path = nil
      proc{load(:album__rf)}.must_raise ArgumentError
      check_output [
        "using album__rf",
        "load stack:[]",
        "loading albums.yml"
      ]
    ensure
      FixtureDependencies.fixture_path = fixture_path
    end
  end
end
end
