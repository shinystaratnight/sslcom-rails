# frozen_string_literal: true

require 'rails_helper'

describe Cdnify do
  let(:cdn_resource) do
    VCR.use_cassette('cdnify_created_resource') do
      Cdnify.create_cdn_resource({ api_key: Rails.application.secrets.cdnify_admin_user_api_key,
                                   resource_name: 'somewebsite',
                                   resource_origin: 'http://www.somewebsite.com' })
    end
  end

  describe 'create a cdn resource' do
    it 'returns a successful response for cdnify request' do
      VCR.use_cassette('cdnify_valid_create_for_cdn') do
        response = cdn_resource
        assert response.parsed_response['resources']
        assert_nil response.parsed_response['errors']
      end
    end

    it 'returns an error with an invalid cdnify request' do
      VCR.use_cassette('cdnify_invalid_create_for_cdn') do
        response = cdn_resource

        assert response.parsed_response['errors']
        assert_nil response.parsed_response['resources']
      end
    end
  end

  describe 'updating a resource' do
    it 'successfuly updates resource' do
      VCR.use_cassette('cdnify_valid_update_request') do
        response = Cdnify.update_cdn_resource({ id: '98b3515', resource_origin: 'http://www.mywebsite.com', resource_name: 'mywebsite', api_key: Rails.application.secrets.cdnify_admin_user_api_key })

        assert_equal response.code, 200
      end
    end

    it 'does not successfuly updates resource' do
      VCR.use_cassette('cdnify_invalid_update_request') do
        response = Cdnify.update_cdn_resource({ id: 'non_existent', resource_origin: 'http://www.mywebsite.com', resource_name: 'mywebsite', api_key: Rails.application.secrets.cdnify_admin_user_api_key })

        assert response.parsed_response['errors']
      end
    end
  end

  describe 'destroying resource/resources' do
    it 'successfully destroys resources' do
      VCR.use_cassette('cdnify_valid_destroy_request') do
        response = Cdnify.destroy_cdn_resources('b4ed84a', Rails.application.secrets.cdnify_admin_user_api_key)

        assert_equal response.code, 204
        assert_equal response.message, 'No Content'
      end
    end
  end
end
