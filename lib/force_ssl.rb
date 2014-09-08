class ForceSSL
  def initialize(app)
    @app = app
  end

  def call(env)
    env["HTTP_ACCEPT"] = "text/html" if env["HTTP_ACCEPT"] == "text/*"
    if env['HTTPS'] == 'on' || env['HTTP_X_FORWARDED_PROTO'] == 'https'# || other_exception(env)
      @app.call(env)
    else
      req = Rack::Request.new(env)
      [301, { "Location" => req.url.gsub(/^http:/, "https:") }, []]
    end
  end

  def other_exception(env)
    #need to be able to allow link.ssl.com and ssl.com without ssl
    !!(env["HTTP_HOST"] =~ /^ssl.com(:\d+)?/ && env["PATH_INFO"]=~/\/.+/)
  end
end