# frozen_string_literal: true

# config/initializers/swagger.rb
module Swagger
  module Docs
    class Config
      def self.transform_path(path, _api_version)
        # Make a distinction between the APIs and API documentation paths.
        "apidocs/#{path}"
      end

      Swagger::Docs::Config.register_apis(
        '1.0' => {
          controller_base_path: '',
          api_file_path: '/',
          base_path: 'sws.sslpki.local:3000',
          clean_directory: true
        }
      )
    end
  end
end
