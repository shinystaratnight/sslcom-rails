# spec/views/orders/new.html.haml_spec.rb

require 'spec_helper'

describe 'orders/new.html.haml' do
  it 'displays public_new layout' do
    # assign(:product, Product.create(name: 'Shirt', price: 50.0))
    @customer = create :customer
    order = create :order
    activate_authlogic
    assign(:current_user, UserSession.create(@customer))

    render

    rendered.should contain('Live Chat')
  end
end
