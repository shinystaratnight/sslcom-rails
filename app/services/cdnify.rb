require 'httparty'

class Cdnify
  def self.create_cdn_resource(params)
    HTTParty.post('https://reseller.cdnify.com/api/v1/resources', {
      basic_auth: { username: params[:api_key], password: 'x'},
      body: { alias: params[:resource_name], origin: params[:resource_origin]}
    })
  end

  def self.destroy_cdn_resources(resource_id, api_key)
    HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id,
      basic_auth: {username: api_key, password: 'x'
    })
  end

  def self.update_cdn_resource(params)
    HTTParty.patch('https://reseller.cdnify.com/api/v1/resources/' + params[:id],
      basic_auth: {username: params[:api_key], password: 'x'},
      body: {alias: params[:resource_name], origin: params[:resource_origin]
    })
  end
end
