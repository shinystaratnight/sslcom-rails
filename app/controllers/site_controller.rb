class SiteController < ApplicationController
  respond_to :xml, :html, only: :sitemap
  layout false, only: [:customers, :paid_cert_orders]

  STANDARD_PAGES = %w(repository restful_api terms_of_use privacy_policy copyright about contact_us news buy_now)

  caches_action :index, expires_in: 1.year, :cache_path => Proc.new { |c| c.params }

  def index
    render action: "buy_now"
  end

  def subject_alternative_name

  end

  #def paid_cert_orders
  #  co = CertificateOrder.nonfree
  #  render :text => proc { |response, output|
  #    output.write "<table><thead><th>date</th><th>ref</th><th>domain</th><th>amount</th></thead>"
  #    co.each do |i|
  #      output.write("<tr>")
  #      output.write("<td>#{co.created_at.strftime("%b %d, %Y")}")
  #      output.write("<td>#{co.ref_num}")
  #      output.write("<td>#{co.csr.try :common_name}")
  #      output.write("<td>#{co.amount}")
  #    end
  #  }
  #end

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
