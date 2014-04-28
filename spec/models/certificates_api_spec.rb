require 'spec_helper'
require 'apis/certificates_api_app'
#require 'spec'
#require 'spec/interop/test'
#require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

#Test::Unit::TestCase.send :include, Rack::Test::Methods


describe "POST on /certificates/v1.0/apply" do
  include Rack::Test::Methods

  def app
    CertificatesApiApp
  end

  let(:user) do
    mock_model User, :login => "joe_test", :password => "random"
  end

  it "stubs :id" do
    user.id.should eql(5)
  end

  it "should create a new certificate order" do
    post '/certificates/v1.0/apply'
    last_response.should be_ok
  end
end