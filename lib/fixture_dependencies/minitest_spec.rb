require 'fixture_dependencies'

class Minitest::Spec
  def load(*args)
    FixtureDependencies.load(*args)
  end

  def load_attributes(*args)
    FixtureDependencies.load_attributes(*args)
  end

  def build(*args)
    FixtureDependencies.build(*args)
  end
end
