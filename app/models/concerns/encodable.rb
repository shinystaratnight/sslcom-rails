module Encodable
  extend ActiveSupport::Concern

  TARGET_ENCODING       = Encoding.find("UTF-8")        # #<Encoding:UTF-8>
  TARGET_ENCODING_NAME  = Encoding.find("UTF-8").to_s   # 'UTF-8'

  # Returns encoded string of the passed string
  def force_string_encoding(str)
    if str.is_a?(String) && str.respond_to?(:force_encoding)
      str = str.dup if str.frozen?
      str.force_encoding(TARGET_ENCODING) if Encoding.compatible?(str.encoding.name, TARGET_ENCODING_NAME)
      str.encode!(TARGET_ENCODING, 'binary', invalid: :replace, undef: :replace, replace: '')
    end
    str
  end
end
