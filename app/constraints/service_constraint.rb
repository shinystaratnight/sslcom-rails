class ServiceConstraint
  def matches?(request)
    return true if Rails.env.test? || Rails.env.development?
    return true if ENV["METRICS_API_KEY"] && request.headers["X_METRICS_API_KEY"] == ENV["METRICS_API_KEY"]
    return false
  end
end
