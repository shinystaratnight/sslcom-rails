class Tracking < ActiveRecord::Base
  belongs_to :visitor_token
  belongs_to :tracked_url
  belongs_to :referer, :class_name => "TrackedUrl", :foreign_key => "referer_id"

  def parents
    Tracking.where{(referer_id == my{tracked_url_id}) & (visitor_token_id == my{visitor_token_id}) &
    (created_at < my{created_at})}.sort{|a,b|a.created_at<=>b.created_at}
  end

  def parent
    parents.last if parents
  end

  def parent_root
    parents.first if parents
  end

  SSL_LINKS = ["http://ssl.com%", "https://ssl.com%", "http://www.ssl.com%", "https://www.ssl.com%",
               "https://ssl/", "http://reseller.ssl.com%", "https://reseller.ssl.com%",
               "http://sws.ssl.com%", "https://sws.ssl.com%","http://staging.ssl.com%", "https://staging1.ssl.com%"]

  scope :non_ssl_com, joins(:tracked_url).where{tracked_urls.url.not_like_all SSL_LINKS}
end
