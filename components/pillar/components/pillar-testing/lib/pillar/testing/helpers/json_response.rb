# frozen_string_literal: true

module Pillar
  module Testing
    module Helpers
      module JSONResponse
        def json_response
          @json_response ||= begin
            request
            JSON.parse(response.body)
          end
        end
      end
    end
  end
end
