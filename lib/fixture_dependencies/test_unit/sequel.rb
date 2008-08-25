require 'fixture_dependencies/test_unit'

class FixtureDependencies::SequelTestCase < Test::Unit::TestCase
  # Work around for Rails stupidity
  undef_method :default_test if method_defined?(:default_test)
  
  def run(*args, &block)
    Sequel::Model.db.transaction do
      super
      raise Sequel::Error::Rollback
    end
  end
end
