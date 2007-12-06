module Test
  module Unit
    class TestCase
      class << self
        alias_method :stupid_method_added, :method_added
      end
      def self.method_added(x)
      end
      
      def setup_with_fixtures
        ActiveRecord::Base.send :increment_open_transactions
        ActiveRecord::Base.connection.begin_db_transaction
        load_fixtures
      end
      alias_method :setup, :setup_with_fixtures

      class << self
        alias_method :method_added, :stupid_method_added
      end
      
      private
        def load_fixtures
          load(*fixture_table_names)
        end
        
        def load(*fixture)
          FixtureDependencies.load(*fixture)
        end
    end
  end
end
