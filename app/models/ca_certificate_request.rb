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

# This class represent requests sent to the CA (ie Comodo or the SSL.com Root CA)

class CaCertificateRequest < CaApiRequest

  def order_number
    m=response.match(/(?<=orderNumber=)(.+?)&/)
    m[1] unless m.blank?
  end

  def certificate_id
    m=response.match(/(?<=certificateID=)(.+?)&/)
    m[1] unless m.blank?
  end

  def total_cost
    m=response.match(/(?<=totalCost=)(.+?)&/)
    m[1].to_f unless m.blank?
  end

  def response_to_hash
    CGI::parse(response)
  end

  def response_value(key=nil)
    codes = response_to_hash
    key.blank? ? codes : (codes[key].blank? ? "" : codes[key][0])
  end

  def unique_value
    response_value("uniqueValue").blank? ? (response =~ /.+?\n.+?\n(.+)?\n/ ; $1) : response_value("uniqueValue")
  end

  def response_error_code
    codes = response_to_hash
    codes['errorCode'].blank? ? "" : codes['errorCode'][0]
  end

  def response_unique_value
    codes = response_to_hash
    codes['uniqueValue'].blank? ? "" : codes['uniqueValue'][0]
  end

  def response_error_message
    codes = response_to_hash
    codes['errorMessage'].blank? ? "" : codes['errorMessage'][0].gsub(/comodo/i,'SSL.com').gsub(/\!AutoApplySSL/,'api access')
  end

  def response_certificate_eta
    codes = response_to_hash
    codes['expectedDeliveryTime'] ? codes['expectedDeliveryTime'][0] : ""
  end

  def response_certificate_status
    codes = response_to_hash
    codes['certificateStatus'] ? codes['certificateStatus'][0] : ""
  end


end
