module PaypalExpressHelper
  def get_setup_purchase_params(cart, request, params)
    subtotal, shipping, total = get_totals(cart)
    return to_cents(total), {
        :ip => request.remote_ip,
        :return_url => url_for(:action => 'purchase', ssl_slug: params[:ssl_slug], :only_path => false, deduct_order: params[:deduct_order]),
        :cancel_return_url => root_url,
        :subtotal => to_cents(subtotal),
        :shipping => to_cents(shipping),
        :handling => 0,
        :tax =>      0,
        :allow_note =>  true,
        :items => get_items(cart),
    }
  end

  def get_order_info(gateway_response, cart)
    subtotal, shipping, total = get_totals(cart)
    {
        shipping_address: gateway_response.address,
        email: gateway_response.email,
        name: gateway_response.name,
        gateway_details: {
            :token => gateway_response.token,
            :payer_id => gateway_response.payer_id,
        },
        subtotal: gateway_response.params['order_total'],
        shipping: gateway_response.params['shipping_total'],
        total: gateway_response.params['order_total']
    }
  end

  def get_shipping(cart)
    # define your own shipping rule based on your cart here
    # this method should return an integer
  end

  def get_items(cart)
    cart.line_items.collect do |line_item|
      if line_item.sellable.is_a?(Deposit)
        {
            :name => "Deposit",
            :number => "sslcomdeposit"
        }
      elsif line_item.sellable.is_a?(ResellerTier)
        product = line_item.sellable
        {
            :name => product.roles,
            :number => product.roles
        }
      else
        product = line_item.sellable.is_a?(CertificateOrder) ? line_item.sellable.certificate : line_item.sellable
        {
            :name => product.title,
            :number => product.serial
        }
      end.merge(quantity: 1, amount: line_item.amount.cents )
    end
  end

  def get_purchase_params(gateway_response, request, params)
    items = gateway_response.params['PaymentDetails']['PaymentDetailsItem']
    items=[items] unless items.is_a?(Array)
    new_items = items.map{|i|
      {amount: to_cents(i['Amount'].to_f * 100),
       name: i['Name'],
       quantity: i['Quantity'],
       Number: i['Number']}
    }
    return to_cents(gateway_response.params['order_total'].to_f * 100), {
        :ip => request.remote_ip,
        :token => gateway_response.token,
        :payer_id => gateway_response.payer_id,
        :subtotal => to_cents(gateway_response.params['order_total'].to_f * 100),
        :shipping => to_cents(gateway_response.params['shipping_total'].to_f * 100),
        :handling => 0,
        :tax =>      0,
        :items =>    new_items
    }
  end

  def get_totals(cart)
    subtotal = cart.amount.cents
    shipping = 0.0
    total = subtotal + shipping
    return subtotal, shipping, total
  end

  def to_cents(money)
    (money*1).round
  end
end
