class Header < SitePrism::Page
  elements :links, '#header a'
  element :need_more_info, "a", :text => "NEED MORE INFO"
  element :in_progress, "a", :text => "IN PROGRESS"
  element :reprocessing, "a", :text => "REPROCESSING"
  element :products, "a", :text => "PRODUCTS"
  element :order_by_csr, "a", :text => "ORDER BY CSR"
  element :show_ev_orders, "a", :text => "SHOW EV ORDERS"
  element :show_ucc_orders, "a", :text => "SHOW UCC ORDERS"
  element :show_premium_orders, "a", :text => "SHOW PREMIUM ORDERS"
  element :show_wildcard_orders, "a", :text => "SHOW WILDCARD ORDERS"
  element :show_test_orders, "a", :text => "SHOW TEST ORDERS"
  element :logout, "a", :text => "LOGOUT"
end