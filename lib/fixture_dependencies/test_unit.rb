require 'fixture_dependencies'

module Test
  module Unit
    class TestCase
      private
      
      # Load given fixtures using FixtureDependencies
      def load(*fixture)
        FixtureDependencies.load(*fixture)
      end
    end
  end
end
