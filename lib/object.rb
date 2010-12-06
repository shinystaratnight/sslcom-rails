class Object

  # Return true if the object can be converted to a valid integer.
  def valid_int?
    begin
      Integer(self)
      true
    rescue ArgumentError
      false
    end
  end
  
  # Return true if the object can be converted to a valid float.
  def valid_float?
    begin
      Float(self)
      true
    rescue ArgumentError
      false
    end 
  end

  # allows attributes to be set with a default value
  def self.attribute(*arg,&block)
    (name, default) = arg
    self.send(:define_method, name) {
      if instance_variables.include? "@#{name}"
           self.instance_eval "@#{name}"
      else
        if block_given?
          instance_eval &block
        else
          default
        end
      end
    }
    self.send(:define_method, "#{name}="){ |value|
      self.instance_eval "@#{name} = value"
    }
  end
end