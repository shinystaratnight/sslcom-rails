object @cc
attributes :errors
child :csr do
  attributes :errors, :common_name, :subject_alternative_names, :days_left
end
