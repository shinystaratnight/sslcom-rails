object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :login, :email, :account_number, :account_key, :secret_key, :status, :user_url, :available_funds
  end
end
