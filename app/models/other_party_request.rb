class OtherPartyRequest < ApplicationRecord
  belongs_to  :other_party_requestable, polymorphic: true
  belongs_to  :user
  serialize   :email_addresses

  validates   :other_party_requestable, :email_addresses, presence: true
  validate    :email_addresses_formats

  before_validation on: :create do |o|
    o.identifier='opvr-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32)
  end

  def email_addresses=(emails)
    write_attribute(:email_addresses, emails.split(/[,\s]/).reject{|e|e.blank?})
  end


  private
  def email_addresses_formats
    return false if email_addresses.blank?
    email_addresses.each do |e|
      unless e =~ EmailValidator::EMAIL_FORMAT
        errors[:base]<<"Ooops, looks like one or more email addresses has an invalid format. Please be sure all email addresses are properly formed."
        break false
      end
    end
  end
end
