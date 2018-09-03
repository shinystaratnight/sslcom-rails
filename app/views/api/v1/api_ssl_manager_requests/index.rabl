object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  collection @results, :object_root => false
  attributes :ref, :ip_address, :mac_address, :friendly_name, :agent, :workflow_status, :created_at, :updated_at
end
