object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :instructions, :md5_hash, :sha2_hash, :dns_sha2_hash, :dcv_methods, :ca_tag
  end
end

