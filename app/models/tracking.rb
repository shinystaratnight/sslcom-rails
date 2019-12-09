class Tracking < ApplicationRecord
  belongs_to :visitor_token
  belongs_to :tracked_url
  belongs_to :referer, :class_name => "TrackedUrl", :foreign_key => "referer_id"

  def parents
    Tracking.where{(referer_id == my{tracked_url_id}) & (visitor_token_id == my{visitor_token_id}) &
    (created_at < my{created_at})}.sort{|a,b|a.created_at.to_i<=>b.created_at.to_i}
  end

  def parent
    parents.last if parents
  end

  def parent_root
    parents.first if parents
  end

  SSL_LINKS = ["/", "http://ssl.com%", "https://ssl.com%", "http://secure.ssl.com%", "https://secure.ssl.com%",
               "https://ssl/", "http://reseller.ssl.com%", "https://reseller.ssl.com%","http://staging1.ssl.com%",
               "http://sws.ssl.com%", "https://sws.ssl.com%","http://staging.ssl.com%", "https://staging1.ssl.com%",
               "http://staging2.ssl.com%", "https://staging2.ssl.com%",
               "http://www.cms.ssl.com%", "https://www.cms.ssl.com%",
               "http://www.fnl.ssl.com%", "https://www.fnl.ssl.com%",
               "http://links.ssl.com%", "https://links.ssl.com%",
               "http://info.ssl.com%", "https://info.ssl.com%"]

  scope :non_ssl_com_url, lambda{joins{tracked_url}.where{tracked_urls.url.not_like_all SSL_LINKS}}
  scope :non_ssl_com_referer, lambda{joins{referer}.where{referer.url.not_like_all SSL_LINKS}}
  scope :affiliate_referers, lambda {|affid|
    joins{tracked_url}.where{tracked_urls.url =~ "%/code/#{affid}%"}
  }

end
