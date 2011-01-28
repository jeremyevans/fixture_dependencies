require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper')

describe FixtureDependencies do
  def load(*a) FixtureDependencies.load(*a) end
  def verbose(i=3)
    v = FixtureDependencies.verbose
    FixtureDependencies.verbose = i
    yield
  ensure
    FixtureDependencies.verbose = v
  end

  after do
    # Clear tables and fixture_dependencies caches
    [:self_refs, :albums_tags, :tags, :albums, :artists].each{|x| DB[x].delete}
    FixtureDependencies.loaded.clear
    FixtureDependencies.fixtures.clear
  end

  it "should load single records with underscore syntax" do
    ym = load(:artist__ym) 
    ym.id.should == 1
    ym.name.should == 'YM'
  end

  it "should load multiple records with underscore syntax and multiple arguments" do
    rf, mo = load(:album__rf, :album__mo) 
    rf.id.should == 1
    rf.name.should == 'RF'
    mo.id.should == 2
    mo.name.should == 'MO'
  end

  it "should load multiple records with hash syntax" do
    rf, mo = load(:albums=>[:rf, :mo]) 
    rf.id.should == 1
    rf.name.should == 'RF'
    mo.id.should == 2
    mo.name.should == 'MO'
  end

  it "should load multiple records with a mix a hashes and symbols" do
    rf, mo = load(:album__rf, :albums=>[:mo]) 
    rf.id.should == 1
    rf.name.should == 'RF'
    mo.id.should == 2
    mo.name.should == 'MO'
  end

  it "should load whole tables at once with single symbol" do
    Artist.count.should == 0
    load(:artists) 
    Artist.count.should == 2
  end

  it "should load whole tables at once with single symbol" do
    Artist.count.should == 0
    Album.count.should == 0
    load(:artists, :albums) 
    Artist.count.should == 2
    Album.count.should == 3
  end

  it "should load associated many_to_one records" do
    rf = load(:album__rf)
    rf.artist.id.should == 1
  end

  it "should load associated one_to_many records" do
    nu = load(:artist__nu)
    nu.albums.length.should == 1
    nu.albums.first.id.should == 3
    nu.albums.first.name.should == 'P'
  end

  it "should load associated many_to_many records and handle cycles (I->P->NU->P)" do
    i = load(:tag__i)
    i.albums.length.should == 1
    p = i.albums.first
    p.id.should == 3
    p.name.should == 'P'
    nu = p.artist
    nu.id.should == 2
    nu.name.should == 'NU'
    nu.albums.length.should == 1
    nu.albums.first.should == p
  end

  it "should not load records that were not asked for" do
    ym = load(:artist__ym) 
    Artist.count.should == 1
    Artist.first.should == ym
    load(:artist__nu)
    Artist.count.should == 2
  end

  it "should handle self referential records" do
    i = load(:self_ref__i)
    i.id.should == 1
    i.self_ref.id.should == 1
    i.self_refs.length.should == 1
    i.self_refs.first.id.should == 1
  end

  it "should handle association cycles" do
    a = load(:self_ref__a)
    a.id.should == 2
    b = a.self_ref
    b.id.should == 3
    c = b.self_ref
    c.id.should == 4
    c.self_ref.should == a
  end

  it "should raise error nonexistent fixture files" do
    class Foo < Sequel::Model; end
    proc{load(:foos)}.should raise_error(ArgumentError)
  end

  it "should raise error for unsupported model classes" do
    class Bar; def self.table_name() :bars end end
    proc{load(:bars)}.should raise_error(TypeError)
  end
end
