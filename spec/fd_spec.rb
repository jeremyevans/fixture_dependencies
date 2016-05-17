require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper')
require 'minitest/autorun'

describe FixtureDependencies do
  def load(*a) FixtureDependencies.load(*a) end
  def load_attributes(*a) FixtureDependencies.load_attributes(*a) end
  def verbose(i=3)
    v = FixtureDependencies.verbose
    FixtureDependencies.verbose = i
    yield
  ensure
    FixtureDependencies.verbose = v
  end

  after do
    # Clear tables and fixture_dependencies caches
    [:ctis, :cti_subs, :cti_mms, :cti_mm_subs, :stis, :com_self_refs, :com_albums_com_tags, :com_tags, :com_albums, :com_artists, :self_refs, :albums_tags, :tags, :albums, :artists, :accounts, :addresses].each{|x| DB[x].delete}
    FixtureDependencies.loaded.clear
    FixtureDependencies.fixtures.clear
  end

  it "should load single records with underscore syntax" do
    ym = load(:artist__ym)
    ym.id.must_equal 1
    ym.name.must_equal 'YM'
  end

  it "should load attributes for single records with underscore syntax" do
    lym = load_attributes(:artist__lym)
    lym.name.must_equal 'LYM'
    lym.id.must_be_nil
  end

  it "should load multiple records with underscore syntax and multiple arguments" do
    rf, mo = load(:album__rf, :album__mo) 
    rf.id.must_equal 1
    rf.name.must_equal 'RF'
    mo.id.must_equal 2
    mo.name.must_equal 'MO'
  end

  it "should load attributes for multiple records with underscore syntax and multiple arguments" do
    lym, lnu = load_attributes(:artist__lym, :artist__lnu)
    lym.name.must_equal 'LYM'
    lym.id.must_equal nil
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal nil
  end

  it "should load multiple records with hash syntax" do
    rf, mo = load(:albums=>[:rf, :mo]) 
    rf.id.must_equal 1
    rf.name.must_equal 'RF'
    mo.id.must_equal 2
    mo.name.must_equal 'MO'
  end

  it "should load attributes for multiple records with hash syntax" do
    lym, lnu = load_attributes(:artists=>[:lym, :lnu])
    lym.name.must_equal 'LYM'
    lym.id.must_equal nil
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal nil
  end

  it "should load multiple records with a mix a hashes and symbols" do
    rf, mo = load(:album__rf, :albums=>[:mo]) 
    rf.id.must_equal 1
    rf.name.must_equal 'RF'
    mo.id.must_equal 2
    mo.name.must_equal 'MO'
  end

  it "should load attributes for multiple records with a mix a hashes and symbols" do
    lym, lnu = load_attributes(:artist__lym, :artists=>[:lnu])
    lym.name.must_equal 'LYM'
    lym.id.must_equal nil
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal nil
  end

  it "should load whole tables at once with single symbol" do
    Artist.count.must_equal 0
    load(:artists) 
    Artist.count.must_equal 4
  end

  it "should load attributes for whole tables at once with single symbol" do
    lnu, lym, nu, ym = load_attributes(:artists).sort_by{|x| x.name}
    ym.name.must_equal 'YM'
    ym.id.must_equal 1
    nu.name.must_equal 'NU'
    nu.id.must_equal 2
    lym.name.must_equal 'LYM'
    lym.id.must_equal nil
    lnu.name.must_equal 'LNU'
    lnu.id.must_equal nil
  end

  it "should load whole tables at once with single symbol" do
    Artist.count.must_equal 0
    Album.count.must_equal 0
    load(:artists, :albums) 
    Artist.count.must_equal 4
    Album.count.must_equal 4
  end

  it "should load associated many_to_one records" do
    rf = load(:album__rf)
    rf.artist.id.must_equal 1
  end

  it "should load associated one_to_many records" do
    nu = load(:artist__nu)
    nu.albums.length.must_equal 1
    nu.albums.first.id.must_equal 3
    nu.albums.first.name.must_equal 'P'
  end

  it "should load associated many_to_one record when loading attributes" do
    q = load_attributes(:album__q)
    q.id.must_equal 4
    q.name.must_equal 'Q'
    q.artist.name.must_equal 'LNU'
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
  end

  it "should not load records that were not asked for" do
    ym = load(:artist__ym) 
    Artist.count.must_equal 1
    Artist.first.must_equal ym
    load(:artist__nu)
    Artist.count.must_equal 2
  end

  it "should handle self referential records" do
    i = load(:self_ref__i)
    i.id.must_equal 1
    i.self_ref.id.must_equal 1
    i.self_refs.length.must_equal 1
    i.self_refs.first.id.must_equal 1
  end

  it "should handle association cycles" do
    a = load(:self_ref__a)
    a.id.must_equal 2
    b = a.self_ref
    b.id.must_equal 3
    c = b.self_ref
    c.id.must_equal 4
    c.self_ref.must_equal a
  end

  it "should raise error nonexistent fixture files" do
    class Foo < Sequel::Model; end
    proc{load(:foos)}.must_raise(ArgumentError)
  end

  it "should raise error for unsupported model classes" do
    class Bar; def self.table_name() :bars end end
    proc{load(:bars)}.must_raise(TypeError)
  end

  next if ENV['FD_AR']

  it "should load single records with underscore syntax" do
    ym = load(:com_artist__ym)
    ym.id1.must_equal 1
    ym.id2.must_equal 2
    ym.name.must_equal 'YM'
  end

  it "should load multiple records with underscore syntax and multiple arguments" do
    rf, mo = load(:com_album__rf, :com_album__mo) 
    rf.id1.must_equal 1
    rf.id2.must_equal 2
    rf.name.must_equal 'RF'
    mo.id1.must_equal 3
    mo.id2.must_equal 4
    mo.name.must_equal 'MO'
  end

  it "should load multiple records with hash syntax" do
    rf, mo = load(:com_albums=>[:rf, :mo]) 
    rf.id1.must_equal 1
    rf.id2.must_equal 2
    rf.name.must_equal 'RF'
    mo.id1.must_equal 3
    mo.id2.must_equal 4
    mo.name.must_equal 'MO'
  end

  it "should load multiple records with a mix a hashes and symbols" do
    rf, mo = load(:com_album__rf, :com_albums=>[:mo]) 
    rf.id1.must_equal 1
    rf.id2.must_equal 2
    rf.name.must_equal 'RF'
    mo.id1.must_equal 3
    mo.id2.must_equal 4
    mo.name.must_equal 'MO'
  end

  it "should load whole tables at once with single symbol" do
    ComArtist.count.must_equal 0
    load(:com_artists) 
    ComArtist.count.must_equal 2
  end

  it "should load whole tables at once with single symbol" do
    ComArtist.count.must_equal 0
    ComAlbum.count.must_equal 0
    load(:com_artists, :com_albums) 
    ComArtist.count.must_equal 2
    ComAlbum.count.must_equal 3
  end

  it "should load associated many_to_one records" do
    rf = load(:com_album__rf)
    rf.artist.id1.must_equal 1
    rf.artist.id2.must_equal 2
  end

  it "should load associated one_to_many records" do
    nu = load(:com_artist__nu)
    nu.albums.length.must_equal 1
    nu.albums.first.id1.must_equal 5
    nu.albums.first.id2.must_equal 6
    nu.albums.first.name.must_equal 'P'
  end

  it "should load associated many_to_many records and handle cycles (I->P->NU->P)" do
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
  end

  it "should handle self referential records" do
    i = load(:com_self_ref__i)
    i.id1.must_equal 1
    i.id2.must_equal 2
    i.self_ref.id1.must_equal 1
    i.self_ref.id2.must_equal 2
    i.self_refs.length.must_equal 1
    i.self_refs.first.id1.must_equal 1
    i.self_refs.first.id2.must_equal 2
  end

  it "should composite and associated primary keys" do
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
  end

  it "should handle STI tables correctly" do
    main, sub, nl = load(:stis=>[:main, :sub, :nil])
    main.class.must_equal Sti
    sub.class.must_equal StiSub
    nl.class.must_equal Sti
  end

  it "should handle STI tables with model maps correctly" do
    main, sub, nl = load(:stys=>[:main, :sub, :nil])
    main.class.must_equal Sty
    sub.class.must_equal StySub
    nl.class.must_equal StySub
  end

  it "should handle CTI tables correctly" do
    main, sub, nl = load(:ctis=>[:main, :sub, :nil])
    main.class.must_equal Cti
    sub.class.must_equal CtiSub
    nl.class.must_equal Cti
  end

  it "should handle CTI tables with model maps correctly" do
    main, sub, nl = load(:cti_mm=>[:main, :sub, :nil])
    main.class.must_equal CtiMm
    sub.class.must_equal CtiMmSub
    nl.class.must_equal CtiMmSub
  end

  it "should load associated many_to_one records" do
    rf = load(:album__rf)
    rf.artist.id.must_equal 1
  end

if defined?(Account) && defined?(Address)
    it "should handle normal fixture correctly" do
      account = load(:account__john)
      account.name.must_equal "John Smith"
    end

    it "should handle polymorphic one_to_many correctly" do
      account = load(:account__john)
      account.name.must_equal "John Smith"

      address = load(:address__john_address)
      address.street.must_equal "743 Evergreen Boulevard"

      account.addresses.must_equal [address]
    end

    it "should handle polymorphic many_to_one correctly" do
      address = load(:address__john_address)
      address.street.must_equal "743 Evergreen Boulevard"

      account = address.addressable
      account.name.must_equal "John Smith"
    end

    it "should handle more than 1 polymorphic correctly" do
      address = load(:address__lym_address)
      address.street.must_equal "123 Walnut Street - Moe's Tavern"

      artist = address.addressable
      artist.name.must_equal "LYM"
    end
  end
end
