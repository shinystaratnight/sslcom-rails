class ForceSSL
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTPS'] == 'on' || env['HTTP_X_FORWARDED_PROTO'] == 'https' || other_exception(env)
      @app.call(env)
    else
      req = Rack::Request.new(env)
      [301, { "Location" => req.url.gsub(/^http:/, "https:") }, []]
    end
  end

  def other_exception(env)
    #need to be able to allow link.ssl.com and ssl.com without ssl
    env["REQUEST_URI"]=~/^(http:\/\/)?ssl\.com/
  end
end