module Merb
  module Test
    module World
      class Webrat
        def load(*args)
          FixtureDependencies.load(*args)
        end
      end
    end
  end
end