# == Schema Information
#
# Table name: ca_api_requests
#
#  id                   :integer          not null, primary key
#  api_requestable_type :string(191)
#  ca                   :string(255)
#  certificate_chain    :text(65535)
#  method               :string(255)
#  parameters           :text(65535)
#  raw_request          :text(65535)
#  request_method       :text(65535)
#  request_url          :text(65535)
#  response             :text(16777215)
#  type                 :string(191)
#  username             :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  api_requestable_id   :integer
#  approval_id          :string(255)
#
# Indexes
#
#  index_ca_api_requests_on_api_requestable                          (api_requestable_id,api_requestable_type)
#  index_ca_api_requests_on_id_and_type                              (id,type)
#  index_ca_api_requests_on_type_and_api_requestable                 (id,api_requestable_id,api_requestable_type,type) UNIQUE
#  index_ca_api_requests_on_type_and_api_requestable_and_created_at  (id,api_requestable_id,api_requestable_type,type,created_at)
#  index_ca_api_requests_on_type_and_username                        (type,username)
#  index_ca_api_requests_on_username_and_approval_id                 (username,approval_id) UNIQUE
#

class ApiDcvEmailResend < ApiCertificateRequest
  validates :account_key, :secret_key, :ref, presence: true
  validates :email_address, email: true, unless: lambda{|c|c.email_address.blank?}
  validates_presence_of  :order_exists, :verify_dcv_email_address, on: :create

  attr_accessor :certificate_order, :sent_at

  def order_exists
    errors[:email_address]<< "certificate order #{ref} does not exist" unless
        certificate_order=CertificateOrder.find_by_ref(ref)
  end


  def verify_dcv_email_address
    if self.email_address
      emails=ComodoApi.domain_control_email_choices(certificate_order.common_name).email_address_choices
      errors[:email_address]<< "must be one of the following: #{emails.join(", ")}" unless
          emails.include?(self.dcv_email_address)
    end
  end

end
