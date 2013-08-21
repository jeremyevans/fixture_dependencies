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

  def log
    DB.loggers << Logger.new($stderr)
    yield
  ensure
    DB.logger = nil
  end

  after do
    # Clear tables and fixture_dependencies caches
    [:stis, :com_self_refs, :com_albums_com_tags, :com_tags, :com_albums, :com_artists, :self_refs, :albums_tags, :tags, :albums, :artists].each{|x| DB[x].delete}
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
    i.albums.length.should == 2
    p = i.albums.first
    p.id.should == 3
    p.name.should == 'P'
    mo = i.albums.last
    mo.id.should == 2
    mo.name.should == 'MO'
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

unless ENV['FD_AR']
  it "should load single records with underscore syntax" do
    ym = load(:com_artist__ym)
    ym.id1.should == 1
    ym.id2.should == 2
    ym.name.should == 'YM'
  end

  it "should load multiple records with underscore syntax and multiple arguments" do
    rf, mo = load(:com_album__rf, :com_album__mo) 
    rf.id1.should == 1
    rf.id2.should == 2
    rf.name.should == 'RF'
    mo.id1.should == 3
    mo.id2.should == 4
    mo.name.should == 'MO'
  end

  it "should load multiple records with hash syntax" do
    rf, mo = load(:com_albums=>[:rf, :mo]) 
    rf.id1.should == 1
    rf.id2.should == 2
    rf.name.should == 'RF'
    mo.id1.should == 3
    mo.id2.should == 4
    mo.name.should == 'MO'
  end

  it "should load multiple records with a mix a hashes and symbols" do
    rf, mo = load(:com_album__rf, :com_albums=>[:mo]) 
    rf.id1.should == 1
    rf.id2.should == 2
    rf.name.should == 'RF'
    mo.id1.should == 3
    mo.id2.should == 4
    mo.name.should == 'MO'
  end

  it "should load whole tables at once with single symbol" do
    ComArtist.count.should == 0
    load(:com_artists) 
    ComArtist.count.should == 2
  end

  it "should load whole tables at once with single symbol" do
    ComArtist.count.should == 0
    ComAlbum.count.should == 0
    load(:com_artists, :com_albums) 
    ComArtist.count.should == 2
    ComAlbum.count.should == 3
  end

  it "should load associated many_to_one records" do
    rf = load(:com_album__rf)
    rf.artist.id1.should == 1
    rf.artist.id2.should == 2
  end

  it "should load associated one_to_many records" do
    nu = load(:com_artist__nu)
    nu.albums.length.should == 1
    nu.albums.first.id1.should == 5
    nu.albums.first.id2.should == 6
    nu.albums.first.name.should == 'P'
  end

  it "should load associated many_to_many records and handle cycles (I->P->NU->P)" do
    i = load(:com_tag__i)
    i.albums.length.should == 1
    p = i.albums.first
    p.id1.should == 5
    p.id2.should == 6
    p.name.should == 'P'
    nu = p.artist
    nu.id1.should == 3
    nu.id2.should == 4
    nu.name.should == 'NU'
    nu.albums.length.should == 1
    nu.albums.first.should == p
  end

  it "should handle self referential records" do
    i = load(:com_self_ref__i)
    i.id1.should == 1
    i.id2.should == 2
    i.self_ref.id1.should == 1
    i.self_ref.id2.should == 2
    i.self_refs.length.should == 1
    i.self_refs.first.id1.should == 1
    i.self_refs.first.id2.should == 2
  end

  it "should composite and associated primary keys" do
    a = load(:com_self_ref__a)
    a.id1.should == 3
    a.id2.should == 4
    b = a.self_ref
    b.id1.should == 5
    b.id2.should == 6
    c = b.self_ref
    c.id1.should == 7
    c.id2.should == 8
    c.self_ref.should == a
  end

  it "should handle STI tables correctly" do
    main, sub, nl = load(:stis=>[:main, :sub, :nil])
    main.class.should == Sti
    sub.class.should == StiSub
    nl.class.should == Sti
  end

  it "should handle STI tables with model maps correctly" do
    main, sub, nl = load(:stys=>[:main, :sub, :nil])
    main.class.should == Sty
    sub.class.should == StySub
    nl.class.should == StySub
  end
end
end
