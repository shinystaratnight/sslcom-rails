class ServerMailInterceptor
  def self.delivering_email(message)
    message.to = ['danielr@ssl.com', 'leo@ssl.com']
  end
end
