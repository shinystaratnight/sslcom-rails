require 'apis/certificates_api_app'

SslCom::Application.routes.draw do
  match '/' => 'site#index', :as => :root
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  resource :account, :controller=>:users do
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

  resources :resellers, :only=>:index do
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
    collection do
      get :credits
      get :pending
      get :incomplete
      get :search
    end

    member do
      put :update_csr
      get :download
      get :renew
      get :reprocess
    end

    resource :validation do
      post :upload, :send_dcv_email
      get :send_to_ca

    end
    resource :site_seal
  end

  resources :certificate_contents do
    resources :contacts, :only=>:index
  end

  resources :csrs do
    resources :signed_certificates
  end

  resources :validation_histories
  resources :validations, :only=>[:index, :update] do
    collection do
      get :search, :requirements, :domain_control, :ev, :organization
    end
  end
  resources :site_seals, :only=>[:index, :update, :admin_update] do
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
      post :create_free_ssl, :create_multi_free_ssl
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
  match 'get_free_ssl' => 'funded_accounts#create_free_ssl',
    :as => :create_free_ssl
  match 'secure/allocate_funds' => 'funded_accounts#allocate_funds',
    :as => :allocate_funds
  match 'secure/allocate_funds_for_order/:id' =>
    'funded_accounts#allocate_funds_for_order', :as => :allocate_funds_for_order
  match 'secure/deposit_funds' => 'funded_accounts#deposit_funds',
    :as => :deposit_funds
  match 'secure/confirm_funds/:id' => 'funded_accounts#confirm_funds',
    :as => :confirm_funds
  match 'secure/apply_funds' => 'funded_accounts#apply_funds',
    :as => :apply_funds
  match 'affiliates/:affiliate_id/orders' => 'orders#affiliate_orders',
    :as => :affiliate_orders
  match ':user_id/orders' => 'orders#user_orders', :as => :user_orders
  match '/sitemap.xml' => 'site#sitemap', :as => :sitemap
  match 'reseller' => 'site#reseller', :as => :reseller,
    :constraints => {:subdomain=>Reseller::SUBDOMAIN}
  match 'browser_compatibility' => 'site#compatibility', as: :browsers
  (Reseller::TARGETED+SiteController::STANDARD_PAGES).each do |i|
    send("match", i=>"site##{i}", :as => i.to_sym)
  end
  match 'certificates/apidocs/apply' => 'restful_api#docs_apply', :as => :restful_apidocs_apply

  #cert api routes
  match '/certificates/v1/apply' => CertificatesApiApp

  match '*disregard/code/:id'=>'affiliates#refer', via: [:get], constraints: {id: /\w+\/?$/}

  match '/:controller(/:action(/:id))'
end
