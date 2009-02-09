class Spec::Example::ExampleGroup
  def execute(*args, &block)
    Sequel::Model.db.transaction{super(*args, &block); raise Sequel::Error::Rollback}
  end

  def load(*args)
    FixtureDependencies.load(*args)
  end
end
