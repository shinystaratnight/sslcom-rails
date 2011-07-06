class SiteController < ApplicationController
  respond_to :xml, :html, only: :sitemap

  STANDARD_PAGES = %w(restful_api terms_of_use privacy_policy copyright about contact_us news)

  def index
  end

  def sitemap
    headers['Content-Type'] = 'application/xml'
    @items = Certificate.sitemap # sitemap is a named scope
    last_item = @items.last
    if stale?(:etag => last_item, :last_modified => last_item.updated_at.utc)
      render action: 'sitemap.xml'
    end
  end
end
