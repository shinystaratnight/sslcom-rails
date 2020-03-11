# frozen_string_literal: true

if defined?(Rswag)
  Rswag::Ui.configure do |c|
    # List the Swagger endpoints that you want to be documented through the swagger-ui
    # The first parameter is the path (absolute or relative to the UI host) to the corresponding
    # endpoint and the second is a title that will be displayed in the document selector
    # NOTE: If you're using rspec-api to expose Swagger files (under swagger_root) as JSON or YAML endpoints,
    # then the list below should correspond to the relative paths for those endpoints

    c.swagger_endpoint '/apidocs', 'API V1 Docs'
  end
end
