class Tracking < ActiveRecord::Base
  belongs_to :visitor_token
  belongs_to :tracked_url
  belongs_to :referer, :class_name => "TrackedUrl", :foreign_key => "referer_id"

end
