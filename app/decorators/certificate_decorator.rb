class CertificateDecorator < ApplicationDecorator
  delegate_all
  decorates_finders

  def last_duration_price
    if object.is_ucc?
      object.first_domains_tiers.last.price * 3
    else
      object.last_duration.price
    end
  end

  def buy_or_get
    object.is_free? ? 'Get' : 'Buy'
  end

  def buy_link(via_root = false)
    if via_root
      h.link_to h.image_tag('buy_bl.gif', title: 'click to buy this certificate', id: "buy-#{object.serial}"), h.buy_certificate_url(object.product_root)
    else
      h.link_to h.image_tag('buy_bl.gif', title: 'click to buy this certificate', id: "buy-#{object.serial}"), h.buy_certificate_url(object)
    end
  end

  def get_link(via_root = false)
    if via_root
      h.link_to h.image_tag('get_bl.gif', title: 'click to get this certificate', id: "get-#{object.serial}"), h.buy_certificate_url(object.product_root)
    else
      h.link_to h.image_tag('get_bl.gif', title: 'click to get this certificate', id: "get-#{object.serial}"), h.buy_certificate_url(object)
    end
  end

  def pricing
    last_duration_pricing
  end

  def last_duration_pricing
    years = object.last_duration.value.to_i/365
    years = 1 unless years > 0
    p = lambda do |c|
      c.decorate.last_duration_price
    end
    price = p.call(object)
    orig_price = p.call(object.untiered)
    actual = (price / years).format
    orig = (object.tiered? ? (orig_price / years).format : nil) unless object.is_dv?
    h.render partial: 'pricing', locals: { actual: actual, orig: orig }
  end

  def new_params
    if object.is_unused_credit?
      [object, { url: :update_csr_certificate_order }]
    elsif object&.ssl_account&.is_registered_reseller?
      object
    else
      [object, { url: :new_order }]
    end
  end
end
