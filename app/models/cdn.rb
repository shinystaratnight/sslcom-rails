class Cdn < ActiveRecord::Base
  belongs_to :ssl_account
  belongs_to :certificate_order
end
