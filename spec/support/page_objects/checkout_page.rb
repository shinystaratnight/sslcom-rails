class CheckoutPage < SitePrism::Page
  set_url '/orders/new'

  element :first_name, '#billing_profile_first_name'
  element :last_name, '#billing_profile_last_name'
  element :company, '#billing_profile_company'
  element :address_1, '#billing_profile_address_1'
  element :address_2, '#billing_profile_address_2'
  element :postal_code, '#billing_profile_postal_code'
  element :city, '#billing_profile_city'
  element :state, '#billing_profile_state'
  element :phone, '#billing_profile_phone'
  element :vat, '#billing_profile_vat'
  element :credit_card, '#billing_profile_credit_card'
  element :card_number, '#billing_profile_card_number'
  element :expiration_month, '#billing_profile_expiration_month'
  element :expiration_year, '#billing_profile_expiration_year'
  element :security_code, '#billing_profile_security_code'
  element :next_button, '.order_next'
  element :paypal_next_button, "a[name='paypal']"
  element :load_from, '#funding_source_paypal'
end
