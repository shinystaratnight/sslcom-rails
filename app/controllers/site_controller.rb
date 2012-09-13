class SiteController < ApplicationController
  respond_to :xml, :html, only: :sitemap

  STANDARD_PAGES = %w(repository restful_api terms_of_use privacy_policy copyright about contact_us news buy_now)

  def index
    sc = SignedCertificate.renew('2012-09-03', '2012-10-13').reject{|sc|sc.csr.certificate_content.blank?}
    co=sc.map(&:certificate_order).uniq.reject{|co|co.certificate.is_free?}
    co.each{|c|c.do_auto_renew}

    render action: "buy_now"
  end

  def sitemap
    # we use online generators now so the dynamic code is kept for legacy purposes
    #headers['Content-Type'] = 'application/xml'
    #@items = Certificate.sitemap # sitemap is a named scope
    #last_item = @items.last
    #if stale?(:etag => last_item, :last_modified => last_item.updated_at.utc)
    #  render action: 'sitemap.xml'
    #end
    if current_subdomain==Reseller::SUBDOMAIN
      render action: 'reseller_sitemap.xml', content_type: 'application/xml', layout: false
    else
      render action: 'sitemap.xml', content_type: 'application/xml', layout: false
    end
  end
end
