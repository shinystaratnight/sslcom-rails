class OtherPartyRequest < ActiveRecord::Base
  belongs_to  :other_party_requestable, polymorphic: true
  serialize   :email_addresses

  validates   :other_party_requestable, :email_addresses, presence: true

  before_create do |o|
    o.identifier='opvr-'+ActiveSupport::SecureRandom.hex(1)+Time.now.to_i.to_s(32)
  end
end
