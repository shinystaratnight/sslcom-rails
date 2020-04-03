class CertificateDecorator < Draper::Decorator
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

  def self.collection_decorator_class
    PaginatingDecorator
  end
end
