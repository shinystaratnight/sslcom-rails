object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :ref, :checkout_in_progress, :is_dv, :is_dv_or_basic, :is_ev, :community_name, :all_domains, :acceptable_file_types, :other_party_request, :subject, :validation_rules
  end
end
