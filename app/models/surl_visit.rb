# == Schema Information
#
# Table name: surl_visits
#
#  id               :integer          not null, primary key
#  http_user_agent  :string(255)
#  referer_address  :string(255)
#  referer_host     :string(255)
#  request_uri      :string(255)
#  result           :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  surl_id          :integer
#  visitor_token_id :integer
#
# Indexes
#
#  index_surl_visits_on_surl_id           (surl_id)
#  index_surl_visits_on_visitor_token_id  (visitor_token_id)
#

class SurlVisit < ApplicationRecord
  belongs_to :surl
  belongs_to :visitor_token
end
