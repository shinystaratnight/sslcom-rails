class CustomeActiveRecord < ActiveRecord::Base
  self.abstract_class = true
  use_connection_ninja(:certassure) if current_domain=~/certassure/i
end