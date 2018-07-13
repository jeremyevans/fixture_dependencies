require('sequel/extensions/inflector') unless [:singularize, :camelize, :underscore, :constantize].all?{|meth| "".respond_to?(meth)}
require 'erb'
require 'yaml'

class FixtureDependencies
  @fixtures = {}
  @loaded = {}
  @class_map = {}
  @verbose = 0
  
  # Load all record arguments into the database. If a single argument is
  # given and it corresponds to a single fixture, return the the model
  # instance corresponding to that fixture.  If a single argument if given
  # and it corresponds to a model, return all model instances corresponding
  # to that model.  If multiple arguments are given, return a list of
  # model instances (for single fixture arguments) or list of model instances
  # (for model fixture arguments).  If no arguments, return the empty list.
  # If any of the arguments is a hash, assume the key specifies the model
  # and the values specify the fixture, and treat it as though individual
  # symbols specifying both model and fixture were given.
  # 
  # Examples:
  # * load(:posts) # All post fixtures, not recommended
  # * load(:posts, :comments) # All post and comment fixtures, again not recommended
  # * load(:post__post1) # Just the post fixture named post1
  # * load(:post__post1, :post__post2) # Post fixtures named post1 and post2
  # * load(:posts=>[:post1, :post2]) # Post fixtures named post1 and post2
  # * load(:post__post1, :comment__comment2) # Post fixture named post1 and comment fixture named comment2
  # * load({:posts=>[:post1, :post2]}, :comment__comment2) # Post fixtures named post1 and post2 and comment fixture named comment2
  #
  # This will load the data from the yaml files for each argument whose model
  # is not already in the fixture hash.
  def self.load(*records)
    load_with_options(records)
  end

  # Load the attributes for the record arguments. This method responds
  # to the same interface as 'load', the difference being that has_many
  # associations are not loaded.
  def self.load_attributes(*records)
    load_with_options(records, :attributes_only=>true)
  end

  # Loads the attribute for a single record, merging optional attributes.
  def self.build(record, attributes = {})
    obj = FixtureDependencies.load_attributes([record])

    attributes.each { |key, value| obj.send("#{key}=", value) }

    obj
  end

  def self.load_with_options(records, opts = {})
    ret = records.map do |record|
      if record.is_a?(Hash)
        record.map do |k, vals|
          model = k.to_s.singularize
          vals.map{|v| :"#{model}__#{v}"}
        end
      else
        record
      end
    end.flatten.compact.map do |record| 
      model_name, name = split_name(record)
      unless class_map[model_name.to_sym].nil?
        record = "#{class_map[model_name.to_sym].to_s.underscore}__#{name}"
      end
      if name
        use(record.to_sym, opts)
      else
        model_name = model_name.singularize
        unless loaded[model_name.to_sym]
          puts "loading #{model_name}.yml" if verbose > 0
          load_yaml(model_name) 
        end
        fixtures[model_name.to_sym].keys.map{|name| use(:"#{model_name}__#{name}", opts)}
      end
    end
    ret.length == 1 ? ret[0] : ret
  end
end

require 'fixture_dependencies/active_record' if defined?(ActiveRecord::Base)
require 'fixture_dependencies/sequel' if defined?(Sequel::Model)
  

class << FixtureDependencies
  attr_reader :fixtures, :loaded
  attr_accessor :verbose, :fixture_path, :class_map
  
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
    model = model_class(model_name)
    model_method(:model_find, model_type(model), model, fixtures[model_name.to_sym][name.to_sym][fixture_pk(model)])
  end
  
  # Adds all fixtures in the yaml fixture file for the model to the fixtures
  # hash (does not add them to the database, see add).
  def load_yaml(model_name)
    raise(ArgumentError, "No fixture_path set. Use FixtureDependencies.fixture_path = ...") unless fixture_path

    klass = model_class(model_name)
    filename = klass.send(klass.respond_to?(:fixture_filename) ? :fixture_filename : :table_name)
    yaml_path = File.join(fixture_path, "#{filename}.yml")

    if File.exist?(yaml_path)
      yaml = YAML.load(File.read(yaml_path))
    elsif File.exist?("#{yaml_path}.erb")
      yaml = YAML.load(ERB.new(File.read("#{yaml_path}.erb")).result)
    else
      raise(ArgumentError, "No valid fixture found at #{yaml_path}[.erb]")
    end

    yaml.each do |name, attributes|
      symbol_attrs = {}
      attributes.each{|k,v| symbol_attrs[k.to_sym] = v}
      add(model_name.to_sym, name, symbol_attrs)
    end
    loaded[model_name.to_sym] = true
  end
  
  # Delegate to the correct method based on mtype
  def model_method(meth, mtype, *args, &block)
    send("#{meth}_#{mtype}", *args, &block)
  end
  
  # A symbol representing the base class of the model, currently
  # ActiveRecord::Base and Sequel::Model are supported.
  def model_type(model)
    if model.ancestors.map(&:to_s).include?('ActiveRecord::Base')
      :AR
    elsif model.ancestors.map(&:to_s).include?('Sequel::Model')
      :S
    else
      raise TypeError, 'not ActiveRecord or Sequel model'
    end
  end

  # Return the class associated with the given model_name.  By default, the
  # class name is automagically derived from the model name, however this
  # can be overridden by <tt>FixtureDependencies.class_map[:name] =
  # Some::Class</tt>.
  def model_class(model_name)
    class_map[model_name.to_sym] || model_name.camelize.constantize
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
  def use(record, opts = {}, loading = [], procs = {})
    spaces = " " * loading.length
    puts "#{spaces}using #{record}" if verbose > 0
    puts "#{spaces}load stack:#{loading.inspect}" if verbose > 1
    loading.push(record)
    model_name, name = split_name(record)
    model = model_class(model_name)
    unless loaded[model_name.to_sym]
      puts "#{spaces}loading #{model.table_name}.yml" if verbose > 0
      load_yaml(model_name)
    end
    mtype = model_type(model)
    model_method(:raise_model_error, mtype, "Couldn't use fixture #{record.inspect}") unless attributes = fixtures[model_name.to_sym][name.to_sym]
    fpk = fixture_pk(model)
    cpk = fpk.is_a?(Array)
    # return if object has already been loaded into the database
    if existing_obj = model_method(:model_find_by_pk, mtype, model, fixture_pkv(attributes,fpk))
      puts "#{spaces}using #{record}: already in database (pk: #{fixture_pkv(attributes,fpk).inspect})" if verbose > 2
      loading.pop
      return existing_obj
    end
    if model.respond_to?(:sti_load)
      obj = model.sti_load(model.sti_key => attributes[model.sti_key])
      obj.send(:initialize)
      model = obj.model
    elsif model.respond_to?(:sti_key)
      obj = attributes[model.sti_key].to_s.camelize.constantize.new
    elsif model.respond_to?(:cti_key) # support for Sequel's pre-4.24.0 hybrid CTI support
      mv = attributes[model.cti_key]
      if (mm = model.cti_model_map)
        model = mm[mv].to_s.constantize
      elsif !mv.nil?
        model = mv.constantize
      end
      obj = model.new
    else
      obj = model.new
    end
    puts "#{spaces}#{model} STI plugin detected, initializing instance of #{obj}" if (verbose > 1 && model.respond_to?(:sti_dataset))
    many_associations = []
    attributes.each do |attr, value|
      next if attr.is_a?(Array)
      if reflection = model_method(:reflection, mtype, model, attr.to_sym)
        if [:belongs_to, :many_to_one].include?(model_method(:reflection_type, mtype, reflection))

          if polymorphic_association?(value)
            value, polymorphic_class = polymorphic_association(value)
            reflection[:class_name] = polymorphic_class
            dep_name = "#{polymorphic_class.to_s.underscore}__#{value}".to_sym
          else
            dep_name = "#{model_method(:reflection_class, mtype, reflection).name.underscore}__#{value}".to_sym
          end

          if dep_name == record
            # Self referential record, use primary key
            puts "#{spaces}#{record}.#{attr}: belongs_to self-referential" if verbose > 1
            attr = model_method(:reflection_key, mtype, reflection)
            value = fixture_pkv(attributes,fpk)
            if cpk
              attr.zip(value).each do |k, v|
                puts "#{spaces}#{record}.#{k} = #{v.inspect}" if verbose > 2
                obj.send("#{k}=", v)
              end
              next
            end
          elsif loading.include?(dep_name)
            # Association cycle detected, set foreign key for this model afterward using procs
            # This is will fail if the column is set to not null or validates_presence_of
            puts "#{spaces}#{record}.#{attr}: belongs-to cycle detected:#{dep_name}" if verbose > 1
            (procs[dep_name] ||= []) << Proc.new do |assoc|
              m = model_method(:model_find, mtype, model, fixture_pkv(attributes,fpk))
              m.send("#{attr}=", assoc)
              model_method(:model_save, mtype, m)
            end
            value = nil
          else
            # Regular assocation, load it
            puts "#{spaces}#{record}.#{attr}: belongs_to:#{dep_name}" if verbose > 1
            use(dep_name, {}, loading, procs)
            value = get(dep_name)
          end
        else
          many_associations << [attr, reflection, value]
          next
        end
      end
      puts "#{spaces}#{record}.#{attr} = #{value.inspect}" if verbose > 2
      obj.send("#{attr}=", value)
    end

    return obj if opts[:attributes_only]

    puts "#{spaces}saving #{record}" if verbose > 1

    model_method(:model_save, mtype, obj)
    # after saving the model, we set the primary key within the fixture hash, in case it was not explicitly specified in the fixture and was generated by an auto_increment / serial field
    fixtures[model_name.to_sym][name.to_sym][fpk] ||= fixture_pkv(obj,fpk)

    loading.pop
    # Update the circular references 
    if procs[record]
      procs[record].each{|p| p.call(obj)} 
      procs.delete(record)
    end
    # Update the has_many and habtm associations
    many_associations.each do |attr, reflection, values|
      Array(values).each do |value|
        dep_name = "#{model_method(:reflection_class, mtype, reflection).name.underscore}__#{value}".to_sym
        rtype = model_method(:reflection_type, mtype, reflection) if verbose > 1
        if dep_name == record
          # Self referential, add association
          puts "#{spaces}#{record}.#{attr}: #{rtype} self-referential" if verbose > 1
          model_method(:add_associated_object, mtype, reflection, attr, obj, obj)
        elsif loading.include?(dep_name)
          # Cycle Detected, add association to this object after saving other object
          puts "#{spaces}#{record}.#{attr}: #{rtype} cycle detected:#{dep_name}" if verbose > 1
          (procs[dep_name] ||= []) << Proc.new do |assoc|
            model_method(:add_associated_object, mtype, reflection, attr, obj, assoc)
          end
        else
          # Regular association, add it
          puts "#{spaces}#{record}.#{attr}: #{rtype}:#{dep_name}" if verbose > 1
          model_method(:add_associated_object, mtype, reflection, attr, obj, use(dep_name, {}, loading, procs))
        end
      end
    end
    obj
  end

  def fixture_pk(model)
    case pk = model.primary_key
    when Symbol, Array
      pk
    else
      pk.to_sym
    end
  end

  def fixture_pkv(attributes, fpk)
    case fpk
    when Symbol
      attributes[fpk]
    else
      fpk.map{|v| attributes[v]}
    end
  end

  # Polymorphic when value has the class indication
  # Example: john (Account)
  #   => true
  def polymorphic_association?(value)
    polymorphic_association(value).size == 2
  end

  # Extract association id and association_class
  # Example: addressable: john (Account)
  #   => ["john", "Account"]
  def polymorphic_association(value)
    value.to_s.scan(/(.*)\s\((.*)\)/).flatten
  end

end
