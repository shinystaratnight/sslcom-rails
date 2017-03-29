module PaypalExpressHelper
  def get_setup_purchase_params(cart, request, params)
    @subtotal, @shipping, @total = get_totals(cart, params)
    @items                       = get_items(cart)
    credit_and_discount params
    load_funds params

    return to_cents(@total), {
      ip:                request.remote_ip,
      return_url:        url_for(action: 'purchase', ssl_slug: params[:ssl_slug], only_path: false, deduct_order: params[:deduct_order]),
      cancel_return_url: root_url,
      subtotal:          to_cents(@total),
      shipping:          to_cents(@shipping),
      handling:          0,
      tax:               0,
      allow_note:        true,
      items:             @items,
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

  def get_totals(cart, params)
    subtotal = cart.amount.cents
    discount = get_amount(params[:discount])
    credit   = get_amount(params[:funded_account])
    surplus  = get_surplus_deposit(params) > 0 ? get_surplus_deposit(params) : 0
    shipping = 0.0
    total    = (subtotal - credit - discount) + surplus + shipping
    return subtotal, shipping, total
  end

  def to_cents(money)
    (money*1).round
  end

  def credit_and_discount(params)
    funded_account_amt = get_amount(params[:funded_account])
    discount_amt       = get_amount(params[:discount])
    
    if params[:discount_code] && (discount_amt > 0)
      @items.push({
        name:     'Discount',
        number:   params[:discount_code],
        quantity: 1,
        amount:   -discount_amt
      })
    end
    # add credit from funded account towards purchase
    if params[:funded_account] && (funded_account_amt > 0)
      @items.push({
        name:     'Funded Account',
        number:   'Credit',
        quantity: 1,
        amount:   -funded_account_amt
      })
    end
  end

  def load_funds(params)
    # load additional (any amount above the purchase amount) to funded account
    if params[:funded_target] && (get_surplus_deposit(params) > 0)
      @items.push({
        name:     'Load Funds',
        number:   'to Funded Account',
        quantity: 1,
        amount:   get_surplus_deposit(params)
      })
    end
  end

  def get_surplus_deposit(params)
    funded      = params[:funded_target]
    final_total = params[:amount].to_i - get_amount(params[:discount]) - get_amount(params[:funded_account])
    funded ? get_amount(funded) - final_total : 0
  end

  def get_amount(amount=nil)
    amount ? (amount.to_f * 100).round : 0
  end
end
