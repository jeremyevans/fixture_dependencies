require_relative '../test_unit'

class FixtureDependencies::SequelTestCase < Test::Unit::TestCase
  # Work around for Rails stupidity
  undef_method :default_test if method_defined?(:default_test)
  
  def run(*args, &block)
    Sequel::Model.db.transaction(:rollback=>:always) do
      super
    end
  end
end
