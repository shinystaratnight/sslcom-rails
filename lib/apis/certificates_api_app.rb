require 'sinatra/base'
class CertificatesApiApp < Sinatra::Base
  set :root, File.dirname(__FILE__)

  post '/certificates/v1.0/apply' do
    'Hello World'
    u=User.last
  end
end
