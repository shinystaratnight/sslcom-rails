object false
if !@result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
<<<<<<< HEAD
    attributes :ref
=======
    attributes :ref, :status
>>>>>>> staging
  end
end
