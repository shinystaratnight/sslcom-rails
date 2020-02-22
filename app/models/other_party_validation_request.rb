# == Schema Information
#
# Table name: other_party_requests
#
#  id                           :integer          not null, primary key
#  email_addresses              :text(65535)
#  identifier                   :string(255)
#  other_party_requestable_type :string(255)
#  sent_at                      :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#  other_party_requestable_id   :integer
#  user_id                      :integer
#
# Indexes
#
#  index_other_party_requests_on_other_party_requestable_id  (other_party_requestable_id)
#  index_other_party_requests_on_user_id                     (user_id)
#

class OtherPartyValidationRequest < OtherPartyRequest
  DCV_SECTION = "dcv"
  DOCUMENTS_SECTION = "documents"
  BOTH_SECTIONS = "both"

  preference  :show_order_number, :default=>false
  preference  :sections, :string, :default=>BOTH_SECTIONS

  validate :allowed_to_create, on: :create

  after_create do |o|
    OtherPartyRequestMailer.request_validation(o).deliver
  end

  def allowed(email)
    email_addresses.include?(email)
  end

  def hide_dcv?
    preferred_sections==DOCUMENTS_SECTION
  end

  def hide_documents?
    preferred_sections==DCV_SECTION
  end

  def hide_both?
    preferred_sections==BOTH_SECTIONS
  end

  private

  def allowed_to_create
    emails=[]
    co = other_party_requestable
    emails << co.ssl_account.cached_users.map(&:email)
    emails << co.other_party_validation_requests.map(&:email_addresses)
    unless emails.flatten.include?(user.email)
      errors[:base]<<"ooops, it looks like you do not have permission to send a request for validation on this order."
    end
  end

end
