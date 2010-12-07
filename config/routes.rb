SslDocs::Application.routes.draw do
  match '/' => 'site#index', :as => :root
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  resource :account do
      resource :reseller
  end

  resources :password_resets
  resource :ssl_account do    
    get :edit_settings
    put :update_settings
  end

  resources :users do
    collection do
      get :edit_password
      get :edit_email
      get :resend_activation
      get :activation_notice
      get :search
    end

    member do
      get :edit_password
      get :edit_email
      get :login_as
      put :admin_update
      get :admin_show
      get :dup_info
      post :consolidate
    end
  end

  resources :resellers do
    collection do
      get :details
      get :restful_api
    end
  end

  resources :reseller_tiers do
    member do
      get :show_popup
    end
  end

  resource :user_session
  resources :certificate_orders do
    resource :validation do
      post :upload
    end
    resource :site_seal
  end

  resources :certificate_contents do
    resources :contacts
  end

  resources :csrs do
    resources :signed_certificates
  end

  resources :validation_histories
  resources :validations do
    collection do
      get :search
    end
  end
  resources :site_seals do
    collection do
      get :details
      get :search
    end
    member do
      get :site_report
      get :artifacts
      put :admin_update
    end
  end

  match '/validation_histories/:id/documents/:style.:extension' =>
    'validation_histories#documents', :as => :validation_document

  resources :orders do
    collection do
      get :show_cart
      get :search
    end
  end

  resources :billing_profiles
  resources :certificates do
    collection do
      get :single_domain
      get :wildcard_or_ucc
    end
    member do
      get :buy
    end

  end

  match '/register/:activation_code' => 'activations#new', :as => :register
  match '/activate/:id' => 'activations#create', :as => :activate
  match 'secure/allocate_funds' => 'funded_accounts#allocate_funds', :as => :allocate_funds
  match 'secure/allocate_funds_for_order/:id' => 'funded_accounts#allocate_funds_for_order', :as => :allocate_funds_for_order
  match 'secure/deposit_funds' => 'funded_accounts#deposit_funds', :as => :deposit_funds
  match 'secure/confirm_funds/:id' => 'funded_accounts#confirm_funds', :as => :confirm_funds
  match 'secure/apply_funds' => 'funded_accounts#apply_funds', :as => :apply_funds
  match 'affiliates/:affiliate_id/orders' => 'orders#affiliate_orders', :as => :affiliate_orders
  match ':user_id/orders' => 'orders#user_orders', :as => :user_orders
  match 'reseller' => 'site#reseller', :as => :reseller,
      :constraints => {:subdomain=>Reseller::SUBDOMAIN}
  (Reseller::TARGETED+%w(restful_api)).each do |i|
    send("match", i=>"site##{i}", :as => i.to_sym)
  end
  match '/:controller(/:action(/:id))'
end
