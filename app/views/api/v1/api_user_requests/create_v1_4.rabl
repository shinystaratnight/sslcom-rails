object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :account_number, :account_key, :secret_key, :status, :user_url
  end
end
