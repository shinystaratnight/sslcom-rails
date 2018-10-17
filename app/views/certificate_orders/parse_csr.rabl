object @cc
attributes :errors
child :csr do
  attributes :errors, :common_name, :subject_alternative_names, :days_left, :public_key_sha1
end
