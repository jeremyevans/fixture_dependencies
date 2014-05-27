require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper')
require 'fixture_dependencies/rspec/sequel'
DB[:artists].delete

describe FixtureDependencies do
  it "should have a load method" do
    DB[:artists].count.should == 0
    ym = load(:artist__ym)
    DB[:artists].count.should == 1
    ym.id.should == 1
    ym.name.should == 'YM'
  end

  it "should run each inside a transation" do
    DB[:artists].count.should == 0
  end
end
