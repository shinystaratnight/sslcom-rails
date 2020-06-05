class AdminConstraint
  def matches?(request)
    return false if request.cookies['user_credentials'].blank?

    user = User.find_by(persistence_token: request.cookies['user_credentials'].split(':')[0])
    user&.is_admin?
  end
end
