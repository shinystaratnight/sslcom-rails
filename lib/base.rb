ActiveRecord::Base.class_eval do
  def model_and_id
    [self.class.to_s.underscore, self.id].join("_")
  end
end
