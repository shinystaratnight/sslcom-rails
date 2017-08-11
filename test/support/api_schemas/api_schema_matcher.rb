# Purpose: Test SSL.com API response body against JSON schema definition.
def match_response_schema(schema)
    JSON::Validator.validate!(
      File.join(Dir.pwd, 'test', 'support', 'api_schemas', "#{schema}.json"),
      JSON.parse(response.body),
      strict: true
    )
end