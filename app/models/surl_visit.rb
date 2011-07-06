class SurlVisit < ActiveRecord::Base
  belongs_to :surl
  belongs_to :visitor_token
end
