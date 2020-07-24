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
#  index_ca_api_requests_on_approval_id                              (approval_id)
#  index_ca_api_requests_on_id_and_type                              (id,type)
#  index_ca_api_requests_on_type_and_api_requestable                 (id,api_requestable_id,api_requestable_type,type) UNIQUE
#  index_ca_api_requests_on_type_and_api_requestable_and_created_at  (id,api_requestable_id,api_requestable_type,type,created_at)
#  index_ca_api_requests_on_type_and_username                        (type,username)
#  index_ca_api_requests_on_username_and_approval_id                 (username,approval_id) UNIQUE
#

class CaMdcStatus < CaApiRequest

  def response_code
    response =~ /\A(\d)\n/
    $1.to_i
  end

  def domain_status
    vals=response.split("&").select{|v|v=~/\d+_/}.map{|s|s.split("=")}.transpose
    unless vals.blank?
      ki, vi, status=1, 0, {}
      (vals[0].count/3).times do |v|
        status.merge!({vals[1][vi]=>{"method"=>vals[1][vi+1].gsub("+"," "),"status"=>vals[1][vi+2].gsub("+"," ")}})
        vi+=3
      end
      status
    end
  end

  def status
    response =~ /.+\n(.+?)\Z/m
    $1
  end

end
