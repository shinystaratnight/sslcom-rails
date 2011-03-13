class SiteController < ApplicationController
  respond_to :xml, :html, only: :sitemap

  def index
    if current_subdomain==Reseller::SUBDOMAIN
      flash.now[:notice] ||= params[:notice]
      render  :action=>'reseller'
    end
  end

  def about
  end

  def help
  end

  def contact_us
  end

  def investors
  end

  def host_providers
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
