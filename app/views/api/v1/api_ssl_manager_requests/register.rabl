object false
if !@result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
<<<<<<< HEAD
    attributes :ref, :created_at, :updated_at
=======
    attributes :ref, :status
    attribute :reason, :unless => lambda { |m| m.reason.nil? }
>>>>>>> staging
  end
end
