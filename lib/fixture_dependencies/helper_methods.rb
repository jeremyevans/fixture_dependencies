require 'fixture_dependencies'

class FixtureDependencies
  module HelperMethods
    # Load given fixtures using FixtureDependencies
    def load(*fixture)
      FixtureDependencies.load(*fixture)
    end

    def load_attributes(*args)
      FixtureDependencies.load_attributes(*args)
    end

    def build(*args)
      FixtureDependencies.build(*args)
    end
  end
end
