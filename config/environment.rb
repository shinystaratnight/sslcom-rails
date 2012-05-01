# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
SslCom::Application.initialize!

#for IDN (unicode names)
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

ActiveRecord::Base.include_root_in_json = true
