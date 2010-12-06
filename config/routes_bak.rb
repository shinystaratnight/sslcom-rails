ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  map.root :controller => "site", :action => "index"
  map.login 'login', :controller => "user_sessions", :action => "new"
  map.logout 'logout', :controller => "user_sessions", :action => "destroy"
  map.resource  :account, :controller => "users"  do |account|
    account.resource :reseller
  end
  map.resources :password_resets
  map.resource :ssl_account, :collection=>{:edit_settings=>:get,
    :update_settings=>:put}
  map.resources :users, :collection=>{:edit_password=>:get, :edit_email=>:get,
    :resend_activation => :get, :activation_notice => :get, 
    :search=>:get}, :member=>{:edit_password=>:get, :edit_email=>:get,
    :login_as=>:get, :admin_update=>:put, :admin_show=>:get, :dup_info=>:get,
    :consolidate=>:post}
  map.resources :resellers, :only=>[:index], :collection=>{:details=>:get,
    :restful_api=>:get}
  map.resources :reseller_tiers, :member => {:show_popup=>:get }
  map.resource  :user_session
  map.resources :certificate_orders, :collection=>{:credits=>:get,
    :pending=>:get, :incomplete=>:get, :search=>:get},
    :member=>{:update_csr=>:put, :download=>:get} do
    |certificate_order|
    certificate_order.resource :validation, :collection=>{:upload => :post}
    certificate_order.resource :site_seal
  end
  map.resources :certificate_contents do |cc|
      cc.resources :contacts, :only=>[:index]
  end
  map.resources :csrs do|csr|
      csr.resources :signed_certificates
  end
  map.resources :validation_histories
  map.resources :validations, :only=>[:index, :update],
    :collection=>{:search=>:get}
  map.resources :site_seals, :only=>[:index, :update, :admin_update],
    :member=>{:site_report => :get, :artifacts=>:get, :admin_update=>:put},
    :collection=>{:details=>:get, :search=>:get}
  map.validation_document '/validation_histories/:id/documents/:style.:extension',
    :controller=>'validation_histories', :action=>'documents'
  map.resources :orders, :collection=>{:show_cart=>:get, :search=>:get}
  map.resources :billing_profiles
  map.resources :certificates, :member => {:buy => :get}, :collection => 
     {:single_domain => :get, :wildcard_or_ucc => :get}
  map.register '/register/:activation_code', :controller => 'activations', :action => 'new'
  map.activate '/activate/:id', :controller => 'activations', :action => 'create'

  map.allocate_funds 'secure/allocate_funds', :controller => 'funded_accounts', :action => 'allocate_funds'
  map.allocate_funds_for_order 'secure/allocate_funds_for_order/:id', :controller => 'funded_accounts', :action => 'allocate_funds_for_order'
  map.deposit_funds 'secure/deposit_funds', :controller => 'funded_accounts', :action => 'deposit_funds'
  map.confirm_funds 'secure/confirm_funds/:id', :controller => 'funded_accounts', :action => 'confirm_funds'
  map.apply_funds 'secure/apply_funds', :controller => 'funded_accounts', :action => 'apply_funds'
  map.affiliate_orders 'affiliates/:affiliate_id/orders', :controller => 'orders', :action => 'affiliate_orders'
  map.user_orders ':user_id/orders', :controller => 'orders', :action => 'user_orders'

  map.with_options(:controller => 'site') do |site|
    site.home '', :action => 'index'
    site.reseller 'reseller', :action => 'reseller',
      :conditions => {:subdomain=>Reseller::SUBDOMAIN}
    (Reseller::TARGETED+%w(restful_api)).each do |i|
      site.send i.to_sym, i, :action=>i
    end
  end

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
