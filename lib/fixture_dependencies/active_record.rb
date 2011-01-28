class << FixtureDependencies
  private
  
  def add_associated_object_AR(reflection, attr, object, assoc)
    if reflection.macro == :has_one
      object.send("#{attr}=", assoc)
    elsif !object.send(attr).include?(assoc)
      object.send(attr) << assoc
    end
  end
  
  def model_find_AR(model, pk)
    model.find(pk)
  end
  
  def model_find_by_pk_AR(model, pk)
    model.send("find_by_#{model.primary_key}", pk)
  end
  
  def model_save_AR(object)
    object.save || raise(ActiveRecord::ActiveRecordError)
  end
  
  def raise_model_error_AR(message)
    raise ActiveRecord::RecordNotFound, message
  end
  
  def reflection_AR(model, attr)
    model.reflect_on_association(attr)
  end
  
  def reflection_class_AR(reflection)
    reflection.klass
  end
  
  def reflection_key_AR(reflection)
    reflection.options[:foreign_key] || reflection.klass.table_name.classify.foreign_key
  end
  
  def reflection_type_AR(reflection)
    reflection.macro
  end
end
