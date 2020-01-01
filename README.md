# fixture_dependencies

fixture_dependencies is an advanced fixture loader, allowing the loading of
models from YAML fixtures, along with their entire dependency graph.  It has
the following features:

- Fixtures specify association names instead of foreign keys
- Support both Sequel and ActiveRecord
- Supports many_to_one/belongs_to, one_to_many/has_many,
  many_to_many/has_and_belongs_to_many, and has_one/one_to_one associations
- Loads a fixture's dependency graph in such a manner that foreign key
  constraints aren't violated
- Has a very simple API (FixtureDependencies.load(:model__fixture))
- Handles almost all cyclic dependencies
- Includes Rails and Sequel test helpers for Test::Unit (and a Sequel test
  helper for RSpec) that load fixtures for every test inside a transaction,
  so fixture data is never left in your database

## Installation

```
  gem install fixture_dependencies
```

## Source

Source is available via github:

```
  http://github.com/jeremyevans/fixture_dependencies
```

You can check it out with git:

```
  git clone git://github.com/jeremyevans/fixture_dependencies.git
```

## Usage

### With Rails/ActiveRecord/Test::Unit:

Add the following to test/test_helper.rb after "require 'test_help'":

```
  require 'fixture_dependencies/test_unit/rails'
```

This overrides the default test helper to load the fixtures inside transactions
and to use FixtureDependencies to load the fixtures.

### With Sequel/Test::Unit:

Somewhere before the test code is loaded:

```
  require 'fixture_dependencies/test_unit/sequel'
```

Make sure the test case classes use FixtureDependencies::SequelTestCase:

```
  class ModelTest < FixtureDependencies::SequelTestCase
```

This runs the test cases inside a Sequel transaction.

### With Sequel/RSpec:

Somewhere before the test code is loaded:

```
  require 'fixture_dependencies/rspec/sequel'
```

This runs each spec inside a separate Sequel transaction.

### With Minitest/Spec:

Somewhere before the test code is loaded:

```
  require 'fixture_dependencies/minitest_spec/sequel'
```

This runs each spec inside a separate Sequel transaction.

### With Rails and Minitest:

You can add the following in your `test_helper.rb` file.

```ruby
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'fixture_dependencies/helper_methods'

class ActiveSupport::TestCase # we are monkey-patching.
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Add more helper methods to be used by all tests here...
  include FixtureDependencies::HelperMethods

  FixtureDependencies.fixture_path = './test/fixtures' # set the path of your fixtures

  def run(*args, &block)
    Sequel::Model.db.transaction(:rollback=>:always){super}
  end
end
```

### With other testing libraries:

You can just use FixtureDependencies.load to handle the loading of fixtures.
The use of transactions is up to you.  One thing you must do if you are
not using the rails test helper is to set the fixture path for
FixtureDependencies:

```
  FixtureDependencies.fixture_path = '/path/to/fixtures'
```

A few helper methods are also available, just include them in your test superclass:

```
  require 'fixture_dependencies/helper_methods'

  class Test < Minitest::Test
    include FixtureDependencies::HelperMethods
  end
```

## Changes to Rails default fixtures:

fixture_dependencies is designed to require the least possible changes to
the default YAML fixtures used by Rails (well, at least Rails 1.2 and earlier).
For example, see the following changes:

```
  OLD                       NEW
  asset1:                   asset1:
  id: 1                     id: 1
  employee_id: 2            employee: jeremy
  product_id: 3             product: nx7010
  vendor_id: 2              vendor: lxg_computers
  note: in working order    note: in working order
```

As you can see, you just replace the foreign key attribute and value with the
name of the association and the associations name.  This assumes you have an
employee fixture with a name of jeremy, and products fixture with the name of
nx7010, and a vendors fixture with the name lxg_computers.

Fixture files still use the table_name of the model. Note that you make sure
to hard code primary key values for each fixture, as shown in the example
above.

## ERB Fixtures

Fixtures can also use ERB to preprocess the fixture file, useful if you need
to do any programming inside the fixture file, such as looping to create
multiple records.  For the ERB support to be invoked, your fixture file
should be named #{table_name}.yml.erb instead of #{table_name}.yml. You can
mix ERB fixture files and regular fixture files, but you can not have an
ERB fixture file and a regular fixture file for the same table (the regular
fixture file will be used in that case).

## Changes to the fixtures Class Method:

fixture_dependencies can still use the fixtures class method in your test:

```
  class EmployeeTest < Test::Unit::TestCase
    fixtures :assets
  end
```

In Rails default testing practices, the arguments to fixtures are table names.
fixture_dependencies changes this to underscored model names.  If you are using
Rails' recommended table practices, this shouldn't make a difference.

It is recommended that you do not use the fixtures method, and instead load
individual fixtures as needed (see below).  This makes your tests much more
robust, in case you want to add or remove individual fixtures at a later date.

## Loading individual fixtures with fixtures class method

There is support for loading individual fixtures (and just their dependencies),
using the following syntax:

```
  class EmployeeTest < Test::Unit::TestCase
    fixtures :employee__jeremy # Note the double underscore
  end
```

This would load just the jeremy fixture and its dependencies.  I find this is
much better than loading all fixtures in most of my test suites.  Even better
is loading just the fixtures you want inside every test method (see below).
This leads to the most robust testing.

## Loading fixtures inside test methods

I find that it is often better to skip the use of the fixtures method entirely,
and load the fixtures I want manually in each test method.  This provides for
the loosest coupling possible.  Here's an example:

```
  class EmployeeTest < Test::Unit::TestCase
    def test_employee_name
      # Load the fixture and return the Employee object
      employee = load(:employee__jeremy)
      # Test the employee
    end

    def test_employees
      # Load the fixtures and return two Employee objects
      employee1, employee2 = load(:employees=>[:jeremy, :karl])
      # Test the employees
    end

    def test_award_statistics
      #  Load all fixtures in both tables
      load(:employee_award__jeremy_first, :award__first)
      # Test the award_statistics method
      #  (which pulls data from the tables loaded above)
    end
  end
```

Don't worry about loading the same fixture twice, if a fixture is already
loaded, it won't attempt to load it again.

## Loading attributes only

You can load only the attributes of fixtures, without saving them with
load\_attributes. This is useful for occasions where you want to mutate
attributes without having to create lots of fixtures or want to test
code that is run before or after the database transaction (validations,
model hooks).

```
# load_attributes responds like load, but without saving the record
fruit = load_attributes(:fruit__banana)
# test the behaviour before saving the record
fruit.save
# test the behaviour after saving the record
```

You can also use the build method for loading the attributes of a
single record, merging the attributes passed as options. This is useful
for testing changes in behaviour when mutating a single parameter:

```
old_banana   = build(:fruit__banana, :age=>'old')
fresh_banana = build(:fruit__banana, :age=>'new')
old_banana.must_be :rotten?
new_banana.wont_be :rotten?
```

## one_to_many/many_to_many/has_many/has_and_belongs_to_many assocations

Here's an example of using has_one (logon_information), has_many (assets), and
has_and_belongs_to_many (groups) associations.

```
  jeremy:
  id: 2
  name: Jeremy Evans
  logon_information: jeremy
  assets: [asset1, asset2, asset3]
  groups: [group1]
```

`logon_information` is a has_one association to another table which was split
from the employees table due to database security requirements.  Assets is a
has_many association, where one employee is responsible for the asset.
Employees can be a member of multiple groups, and each group can have multiple
employees.

For `has_*` associations, after fixture_dependencies saves jeremy, it will load
and save logon_information (and its dependencies...), it will load each asset
in the order specified (and their dependencies...), and it will load all of the
groups in the order specified (and their dependencies...).  Note that there
is only a load order inside a specific association, associations are stored
in the same hash as attributes and are loaded in an arbitrary order.

## many_to_many/has_and_belongs_to_many join table fixtures

Another change is that Rails defaults allow you to specify habtm join tables in
fixtures.  That doesn't work with fixture dependencies, as there is no
associated model.  Instead, you use a has_and_belongs_to_many association name
in the the appropriate model fixtures (see above).

## belongs_to/many_to_one polymorphic fixtures

ActiveRecord supports polymorphic associations by default. With Sequel, this
is made via the `sequel_polymorphic` gem.

Here the mapping in Rails:

```
class Animal < ActiveRecord::Base
  has_many :fruits, as: :eater
end
class Fruit < ActiveRcord::Base
  belongs_to :eater, polymorphic: true
end
```

And here on Sequel:

```
require 'sequel_polymorphic'
class Animal < Sequel::Model
  plugin :polymorphic
  ony_to_many :fruits, as: :eater
end
class Fruit < Sequel::Model
  plugin :polymorphic
  many_to_one :eater, polymorphic: true
end
```

In both cases, the fixtures looks like:

`animals.yml`:

```
george:
  id: 1
  name: George
```

`fruits.yml`:

```
apple:
  id: 1
  name: Apple
  eater: george (Animal)
```

In your test, use something like this:

```
apple = load(:fruit__apple)
apple.eater.name.must_equal "George"
```

fixture_dependencies will set the `eater` association in `Fruit` instance `george` instance of `Animal`.

## Cyclic dependencies

fixture_dependencies handles almost all cyclic dependencies.  It handles all
has_many, has_one, and habtm cyclic dependencies.  It handles all
self-referential cyclic dependencies.  It handles all belongs_to cyclic
dependencies except the case where there is a NOT NULL or validates_presence of
constraint on the cyclic dependency's foreign key.

For example, a case that won't work is when employee belongs_to supervisor
(with a NOT NULL or validates_presence_of constraint on supervisor_id), and
john is karl's supervisor and karl is john's supervisor. Since you can't create
john without a valid supervisor_id, you need to create karl first, but you
can't create karl for the same reason (as john doesn't exist yet).

There isn't a generic way to handle the belongs_to cyclic dependency, as far as
I know.  Deferring foreign key checks could work, but may not be enabled (and
one of the main reasons to use the plugin is that it doesn't require them).
For associations like the example above (employee's supervisor is also an
employee), setting the foreign_key to the primary key and then changing it
later is an option, but database checks may prevent it.  For more complex
cyclic dependencies involving multiple model classes (employee belongs_to
division belongs_to head_of_division when the employee is a member of the
division and also the head of the division), even that approach is not
possible.

## Known issues

Currently, the plugin only supports YAML fixtures, but other types of fixtures
would be fairly easy to add (send me a patch if you add support for another
fixture type).

The plugin is significantly slower than the default testing method, because it
loads all fixtures inside of a transaction (one per test method), where Rails
defaults to loading the fixtures once per test suite (outside of a
transaction), and only deletes fixtures from a table when overwriting it with
new fixtures.

Instantiated fixtures are not available with this plugin.  Instead, you should
use load(:model__fixture_name).

## Namespace Issues

By default, fixture dependencies is going to load the model with the camelized
name in the symbol used.  So for :foo_bar__baz, it's going to look for
the fixture with name baz for the model FooBar.  If your model is namespaced,
such as Foo::Bar, this isn't going to work well.  In that case, you can
override the default mapping:

```
  FixtureDependencies.class_map[:bar] = Foo::Bar
```

and then use :bar__baz to load the fixture with name baz for the model
Foo::Bar.

## Custom Fixture Filenames

Fixture dependencies will look for a file that corresponds to the table name
for the model by default. You can override this by defining a fixtures_filename
class method in the model:

```
  class Artist < Sequel::Model
    def self.fixture_filename
      :artists_custom_fixture_file
    end
  end
```

## Troubleshooting

If you run into problems with loading your fixtures, it can be difficult to see
where the problems are.  To aid in debugging an error, add the following to
test/test_helper.rb:

```
  FixtureDependencies.verbose = 3
```

This will give a verbose description of the loading and saving of fixtures for
every test, including the recursive loading of the dependency graph.

## Specs

The specs for fixture dependencies and be run with Rake.  They require
the sequel, activerecord, and sqlite3 gems installed.  The default rake task
runs the specs.  You should run the spec_migrate task first to create the
spec database.

## Similar Ideas

Rails now supports something similar by default.  Honestly, I'm not sure what
the differences are.

fixture_references is a similar plugin.  It uses erb inside yaml, and uses the
foreign key numbers inside of the association names, which leads me to believe
it doesn't support has_* associations.

## Sample Rails App with Fixtures Working

Check out [this app which features Fixtures and Minitest and steps to enable you to replicate it](https://github.com/BKSpurgeon/testing_in_sequel).

## License

fixture_dependencies is released under the MIT License.  See the MIT-LICENSE
file for details.

## Author

Jeremy Evans <code@jeremyevans.net>
