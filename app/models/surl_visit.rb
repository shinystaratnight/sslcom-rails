class SurlVisit < ApplicationRecord
  belongs_to :surl
  belongs_to :visitor_token
end
