class FixtureDependencies
  @fixtures = {}
  @loaded = {}
  @verbose = 0
  class << self
    attr_reader :fixtures, :loaded
    attr_accessor :verbose
    # Load all record arguments into the database. If a single argument is
    # given and it corresponds to a single fixture, return the the model
    # instance corresponding to that fixture.  If a single argument if given
    # and it corresponds to a model, return all model instances corresponding
    # to that model.  If multiple arguments are given, return a list of
    # model instances (for single fixture arguments) or list of model instances
    # (for model fixture arguments).  If no arguments, return the empty list.
    #
    # This will load the data from the yaml files for each argument whose model
    # is not already in the fixture hash.
    def load(*records)
      ret = records.collect do |record| 
        model_name, name = split_name(record)
        if name
          use(record.to_sym)
        else
          model_name = model_name.singularize
          unless loaded[model_name.to_sym]
            puts "loading #{model_name}.yml" if verbose > 0
            load_yaml(model_name) 
          end
          fixtures[model_name.to_sym].keys.collect{|name| use("#{model_name}__#{name}".to_sym)}
        end
      end
      records.length == 1 ? ret[0] : ret
    end
    
    private
      # Add a fixture to the fixture hash (does not add to the database,
      # just makes it available to be add to the database via use).
      def add(model_name, name, attributes)
        (fixtures[model_name.to_sym]||={})[name.to_sym] = attributes
      end
      
      # Get the model instance that already exists in the database using
      # the fixture name.  
      def get(record)
        model_name, name = split_name(record)
        model = model_name.classify.constantize
        model.find(fixtures[model_name.to_sym][name.to_sym][model.primary_key.to_sym])
      end
      
      # Adds all fixtures in the yaml fixture file for the model to the fixtures
      # hash (does not add them to the database, see add).
      def load_yaml(model_name)
        YAML.load(File.read(File.join(Test::Unit::TestCase.fixture_path, "#{model_name.classify.constantize.table_name}.yml"))).each do |name, attributes|
          symbol_attrs = {}
          attributes.each{|k,v| symbol_attrs[k.to_sym] = v}
          add(model_name.to_sym, name, symbol_attrs)
        end
        loaded[model_name.to_sym] = true
      end
      
      # Split the fixture name into the name of the model and the name of
      # the individual fixture.
      def split_name(name)
        name.to_s.split('__', 2)
      end
      
      # Load the individual fixture into the database, by loading all necessary
      # belongs_to dependencies before saving the model, and all has_*
      # dependencies after saving the model.  If the model already exists in
      # the database, return it.  Will check the yaml file for fixtures if no
      # fixtures yet exist for the model.  If the fixture isn't in the fixture
      # hash, raise an error.
      def use(record, loading = [], procs = {})
        spaces = " " * loading.length
        puts "#{spaces}using #{record}" if verbose > 0
        puts "#{spaces}load stack:#{loading.inspect}" if verbose > 1
        loading.push(record)
        model_name, name = split_name(record)
        model = model_name.classify.constantize
        unless loaded[model_name.to_sym]
          puts "#{spaces}loading #{model.table_name}.yml" if verbose > 0
          load_yaml(model_name) 
        end
        raise ActiveRecord::RecordNotFound, "Couldn't use fixture #{record.inspect}" unless attributes = fixtures[model_name.to_sym][name.to_sym]
        # return if object has already been loaded into the database
        if existing_obj = model.send("find_by_#{model.primary_key}", attributes[model.primary_key.to_sym])
          return existing_obj
        end
        obj = model.new
        many_associations = []
        attributes.each do |attr, value|
          if reflection = model.reflect_on_association(attr.to_sym)
            if reflection.macro == :belongs_to
              dep_name = "#{reflection.klass.name.underscore}__#{value}".to_sym
              if dep_name == record
                # Self referential record, use primary key
                puts "#{spaces}#{record}.#{attr}: belongs_to self-referential" if verbose > 1
                attr = reflection.options[:foreign_key] || reflection.klass.table_name.classify.foreign_key
                value = attributes[model.primary_key.to_sym]
              elsif loading.include?(dep_name)
                # Association cycle detected, set foreign key for this model afterward using procs
                # This is will fail if the column is set to not null or validates_presence_of
                puts "#{spaces}#{record}.#{attr}: belongs-to cycle detected:#{dep_name}" if verbose > 1
                (procs[dep_name] ||= []) << Proc.new do |assoc|
                  m = model.find(attributes[model.primary_key.to_sym])
                  m.send("#{attr}=", assoc)
                  m.save!
                end
                value = nil
              else
                # Regular assocation, load it
                puts "#{spaces}#{record}.#{attr}: belongs_to:#{dep_name}" if verbose > 1
                use(dep_name, loading, procs)
                value = get(dep_name)
              end
            elsif
              many_associations << [attr, reflection, reflection.macro == :has_one ? [value] : value]
              next
            end
          end
          obj.send("#{attr}=", value)
        end
        puts "#{spaces}saving #{record}" if verbose > 1
        obj.save!
        loading.pop
        # Update the circular references 
        if procs[record]
          procs[record].each{|p| p.call(obj)} 
          procs.delete(record)
        end
        # Update the has_many and habtm associations
        many_associations.each do |attr, reflection, values|
          proxy = obj.send(attr)
          values.each do |value|
            dep_name = "#{reflection.klass.name.underscore}__#{value}".to_sym
            if dep_name == record
              # Self referential, add association
              puts "#{spaces}#{record}.#{attr}: #{reflection.macro} self-referential" if verbose > 1
              reflection.macro == :has_one ? (proxy = obj) : (proxy << obj)
            elsif loading.include?(dep_name)
              # Cycle Detected, add association to this object after saving other object
              puts "#{spaces}#{record}.#{attr}: #{reflection.macro} cycle detected:#{dep_name}" if verbose > 1
              (procs[dep_name] ||= []) << Proc.new do |assoc| 
                reflection.macro == :has_one ? (proxy = assoc) : (proxy << assoc unless proxy.include?(assoc))
              end
            else
              # Regular association, add it
              puts "#{spaces}#{record}.#{attr}: #{reflection.macro}:#{dep_name}" if verbose > 1
              assoc = use(dep_name, loading, procs)
              reflection.macro == :has_one ? (proxy = assoc) : (proxy << assoc unless proxy.include?(assoc))
            end
          end
        end
        obj
      end
  end
end
