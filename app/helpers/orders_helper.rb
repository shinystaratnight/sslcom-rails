module OrdersHelper
  def cart_items
    if current_user && current_user.ssl_account.has_role?('new_reseller')
      return [current_user.ssl_account.reseller.reseller_tier]
    elsif @certificate_order
      return [@certificate_order]
    elsif @certificate_orders
      certs=[]
      @certificate_orders.each do |cert|
        cert.quantity.times do
          certs<<cert
        end
      end
      return certs
    elsif @funded_account
      return []
    end
    session[:cart_items] ||= []
    Order.cart_items session, cookies
    session[:cart_items].collect {|cart_item|
      coa = cart_item.split(/,/)
      if (coa.count > 1)
        Certificate.find_by_product(coa.first)
      else
        ActiveRecord::Base.find_from_model_and_id(cart_item)
      end
    }
  end

  def cart_items_count
    cookies[:cart].blank? ? 0 : cookies[:cart].split(":").count
  end

  def current_order
    order = current_user.nil? ? User.new.build_ssl_account.purchase(*cart_items) :
      current_user.ssl_account.purchase(*cart_items)
    order.line_items.each_with_index{|line_item,i|
      affiliates_credits = 
        (cookies[:aid_li].blank? ? nil : cookies[:aid_li].split(/:/).last)
      line_item.affiliate = Affiliate.find(affiliates_credits) if
      Affiliate.exists?(affiliates_credits)
      }
    order.cents = cart_items.inject(0){|result, element| result +
        element.attributes_before_type_cast["amount"].to_f}
    order
  end

  def is_current_order_affordable?
    current_user.ssl_account.funded_account.amount.cents >
      current_order.amount.cents
  end

  def cart_total_price
    Money.new(cart_items.sum(&:amount)).format :with_currency => true
  end

  def min_cart_item_price
    Money.new(cart_items.minimum(&:amount)).format :with_currency => true
  end

  def max_cart_item_price
    Money.new(cart_items.maximum(&:amount)).format :with_currency => true
  end

  def avg_cart_item_price
    Money.new(cart_items.average(&:amount)).format :with_currency => true
  end

  def link_to_checkout
    if cart_items.size > 0 and logged_in? and !current_user.funded_account.blank? and (current_user.funded_account.amount.cents >= current_order.amount.cents)
      link_to "Checkout", confirm_funds_path
    elsif cart_items.size > 0
      link_to "Checkout", allocate_funds_for_order_path
    end
  end

  def apply_order
    (@order.cents > 0 or @order.is_free?) and @funded_account.deduct_order?
  end

  def display_line_items(order, formatted=true)
    content_tag("div", order.line_items.inject("") {|str, line_item|
      str << content_tag("div", "#{line_item.sellable.class.to_s} -
        #{line_item.sellable.description.shorten(20,false)}",
        :class => "line_item_receipt")}, :class=> "line_items_receipt")
  end

  def is_cart_empty?
    cart_items.size==0
  end

  def ssl_account
    current_user.ssl_account
  end

  def reseller_initial_deposit?
    ssl_account.has_role?('new_reseller') &&
      (ssl_account.reseller.enter_billing_information? ||
        ssl_account.reseller.select_tier?)
  end

  def is_receipt?
    (@deposit && @deposit.receipt) || (@order && @order.receipt)
  end

  def determine_eligibility_to_buy
    unless current_user.blank?
      current_user.ssl_account.clear_new_certificate_orders
      unless current_user.ssl_account.can_buy?(@certificate)
        flash[:error].now = "Certificate belongs to a pricing tier which differs
          from your reseller tier level"
        return render(:template => "/certificates/buy", :layout=>"application")
      else
        @certificate_order.ssl_account = current_user.ssl_account
      end
    end
  end
  
  def setup_certificate_order
    #adjusting duration to reflect number of days validity
    duration = @certificate_order.duration.to_i * 365
    @certificate_order.certificate_contents[0].duration = duration
    if @certificate.is_ucc? || @certificate.is_wildcard?
      psl = @certificate.items_by_server_licenses.find{|item|
        item.value==duration.to_s}
      so = SubOrderItem.new(:product_variant_item=>psl,
        :quantity=>@certificate_order.server_licenses.to_i,
        :amount=>psl.amount*@certificate_order.server_licenses.to_i)
      @certificate_order.sub_order_items << so
      if @certificate.is_ucc?
        pd = @certificate.items_by_domains.find_all{|item|
          item.value==duration.to_s}
        additional_domains = (@certificate_order.certificate_contents[0].
          domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
        so = SubOrderItem.new(:product_variant_item=>pd[0],
          :quantity=>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
          :amount=>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
        @certificate_order.sub_order_items << so
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
            :quantity=>additional_domains,
            :amount=>pd[1].amount*additional_domains)
          @certificate_order.sub_order_items << so
        end
      end
    end
    unless @certificate.is_ucc?
      pvi = @certificate.items_by_duration.find{|item|item.value==duration.to_s}
      so = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
        :amount=>pvi.amount)
      @certificate_order.sub_order_items << so
    end
    @certificate_order.amount = @certificate_order.sub_order_items.map(&:amount).sum
    @certificate_order.certificate_contents[0].
      certificate_order = @certificate_order
  end
end
