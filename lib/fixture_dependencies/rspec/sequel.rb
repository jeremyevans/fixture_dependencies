require_relative '../helper_methods'

if defined?(RSpec)
  example_group = RSpec::Core::ExampleGroup
  use_rspec_configure = begin
    require 'rspec/core/version'
  rescue LoadError
    require 'rspec/version'
    RSpec::Version::STRING >= '2.8.0'
  end

  if use_rspec_configure
    RSpec.configure do |c|
      c.around(:each) do |example|
        Sequel::Model.db.transaction(:rollback=>:always){example.run}
      end
    end
  else
    def example_group.inherited(subclass)
      super
      subclass.around do |example|
        Sequel::Model.db.transaction(:rollback=>:always){example.call}
      end
    end
  end
else
  example_group = Spec::Example::ExampleGroup
  example_group.class_eval do
    def execute(*args, &block)
      x = nil
      Sequel::Model.db.transaction(:rollback=>:always){x = super(*args, &block)}
      x
    end
  end
end

example_group.send(:include, FixtureDependencies::HelperMethods)
