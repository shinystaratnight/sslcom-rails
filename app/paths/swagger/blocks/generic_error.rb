module SwaggerResponses
  module GenericError
    def self.extended(base)
      base.response :error do
        key :description, 'Error Response'
        schema do
          key :'$ref', :ErrorResponse
        end
      end
    end
  end
end
