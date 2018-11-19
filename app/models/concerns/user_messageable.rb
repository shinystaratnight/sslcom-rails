module UserMessageable
  extend ActiveSupport::Concern
  
  class_methods do
    
  end
  
  def mailboxer_name
    name = "#{self.first_name} #{self.last_name}"
    self.email if name.strip.empty?
  end

  def mailboxer_email(object)
    self.email
  end

end
