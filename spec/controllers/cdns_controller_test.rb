require 'test_helper'
require 'httparty'

# TODO: Find a way to remove the api credentials from this file
describe CdnsController do
  describe 'create' do
    # TODO: Remove api credentials for testing
    let(:params) do
      { api_key: Rails.application.secrets.cdnify_admin_user_api_key,
        resource_name: 'somewebsite', resource_origin: 'http://www.somewebsite.com' }
    end

    it 'correctly creates a cdn resource' do
      VCR.use_cassette('cdnify_valid_create_for_cdn') do
        post :create, params: params
        assert 'Successfully Created Resource.', flash[:notice]
      end
    end

    it 'fails to creates a cdn resource' do
      VCR.use_cassette('cdnify_invalid_create_for_cdn') do
        post :create, params: params
        assert flash[:error]
      end
    end
  end

  describe 'update_resource' do
    let(:params) do
      { id: '98b3515', api_key: Rails.application.secrets.cdnify_admin_user_api_key,
        resource_name: 'somewebsite', resource_origin: 'http://www.somewebsite.com' }
    end
    let(:invalid_params) do
      { id: 'non_existent', api_key: Rails.application.secrets.cdnify_admin_user_api_key,
        resource_name: 'somewebsite', resource_origin: 'http://www.somewebsite.com' }
    end

    it 'successfully updates a cdn resource' do
      VCR.use_cassette('cdnify_valid_update_request') do
        patch :update_resource, params

        assert_equal 'Successfully Updated General Settings.', flash[:notice]
      end
    end

    it 'does not successfully updates a cdn resource' do
      VCR.use_cassette('cdnify_invalid_update_request') do
        patch :update_resource, invalid_params

        assert flash[:error]
      end
    end
  end

  describe 'delete_resources' do
    it 'successfully destroys a cdn resource' do
      VCR.use_cassette('cdnify_valid_destroy_request') do
        delete :delete_resources,  deleted_resources: ["b4ed84a|heroku|#{Rails.application.secrets.cdnify_admin_user_api_key}"]

        assert_equal 'Resources Successfully Deleted.', flash[:notice]
      end
    end

    it 'fails to destroy selected resources' do
      VCR.use_cassette('cdnify_invalid_destroy_request') do
        delete :delete_resources, deleted_resources: ["non_existent|heroku|#{Rails.application.secrets.cdnify_admin_user_api_key}"]

        assert flash[:error]
      end
    end
  end
end
