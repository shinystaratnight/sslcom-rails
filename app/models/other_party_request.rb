class OtherPartyRequest < ActiveRecord::Base
  belongs_to :other_party_requestable
  serialize :email_addresses
end
