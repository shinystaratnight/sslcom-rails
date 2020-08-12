class ServiceConstraint
  def matches?(request)
    token = bearer_token(request)
    # return true if Rails.env.test? || Rails.env.development?
    return true if ENV["METRICS_API_KEY"] && token == ENV["METRICS_API_KEY"]
    return false
  end

  def bearer_token(request)
    pattern = /^Bearer /
    header  = request.headers['Authorization']
    header.gsub(pattern, '') if header && header.match(pattern)
  end
end
