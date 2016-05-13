require 'apis/certificates_api_app'

SslCom::Application.routes.draw do
  resources :oauth_clients

  get '/oauth/test_request',  :to => 'oauth#test_request',  :as => :test_request

  get '/oauth/token',         :to => 'oauth#token',         :as => :token

  get '/oauth/access_token',  :to => 'oauth#access_token',  :as => :access_token

  get '/oauth/request_token', :to => 'oauth#request_token', :as => :request_token

  get '/oauth/authorize',     :to => 'oauth#authorize',     :as => :authorize

  get '/oauth',               :to => 'oauth#index',         :as => :oauth

  get ''=>'surls#index', :constraints => {:subdomain=>Surl::SUBDOMAIN}, as: 'surls_root'
  get '/'=>'resellers#index', :constraints => {:subdomain=>Reseller::SUBDOMAIN}, as: 'resellers_root'
  get '/' => 'site#index', :as => :root
  get 'login' => 'user_sessions#new', :as => :login
  get 'logout' => 'user_sessions#destroy', :as => :logout

  resources :unsubscribes, only: [:edit, :update]
  #resources :site_checks
  get 'site_check' => 'site_checks#new', :as => :site_check
  get 'site_checks' => 'site_checks#create', :as => :site_checks

  # api
  constraints DomainConstraint.new(
                  %w(sws.sslpki.local sws-test.sslpki.local sws.sslpki.com sws-test.sslpki.com
                  api.certassure.local api-test.certassure.local api.certassure.com api-test.certassure.com)) do
    match '/users' => 'api_user_requests#create_v1_4',
          :as => :api_user_create_v1_4, via: [:post]
    match '/user/:login' => 'api_user_requests#show_v1_4',
          :as => :api_user_show_v1_4, via: [:get], login: /.+\/?/
    match '/certificates/1.3/create' => 'api_certificate_requests#create_v1_3',
          :as => :api_certificate_create_v1_3, via: [:get]
    match '/certificates' => 'api_certificate_requests#create_v1_4',
          :as => :api_certificate_create_v1_4, via: [:post]
    match '/certificate/:ref' => 'api_certificate_requests#update_v1_4',
          :as => :api_certificate_update_v1_4, via: [:put], ref: /[a-z0-9\-]+/
    match '/certificate/:ref' => 'api_certificate_requests#show_v1_4',
          :as => :api_certificate_show_v1_4, via: [:get], ref: /[a-z0-9\-]+/
    match '/certificates/' => 'api_certificate_requests#index_v1_4',
          :as => :api_certificate_index_v1_4, via: [:get]
    match '/certificates/validations/email' => 'api_certificate_requests#dcv_emails_v1_3',
          :as => :api_dcv_emails_v1_4, via: [:get]
    match '/certificate/:ref/validations/methods' => 'api_certificate_requests#dcv_methods_v1_4',
          :as => :api_dcv_methods_v1_4, via: [:get]
    match '/certificate/:ref/api_parameters/:api_call' => 'api_certificate_requests#api_parameters_v1_4',
          :as => :api_parameters_v1_4, via: [:get]
    match '/scan/:url' => 'api_certificate_requests#scan', :as => :api_scan, via: [:get],
          :constraints => { :url => /[^\/]+/ }
    match '/analyze/:url' => 'api_certificate_requests#analyze', :as => :api_analyze, via: [:get],
          :constraints => { :url => /[^\/]+/ }
    match '/certificates/validations/csr_hash' => 'api_certificate_requests#dcv_methods_csr_hash_v1_4',
          :as => :api_dcv_methods_csr_hash_v1_4, via: [:post]
    match '/certificates/1.3/retrieve' => 'api_certificate_requests#retrieve_v1_3',
          :as => :api_certificate_retrieve_v1_3, via: :get
    match '/certificates/1.3/dcv_emails' => 'api_certificate_requests#dcv_emails_v1_3',
          :as => :api_dcv_emails_v1_3, via: [:get, :post]
    match '/certificates/1.3/dcv_email_resend' => 'api_certificate_requests#dcv_email_resend_v1_3',
          :as => :api_dcv_email_resend_v1_3, via: :get
    match '/certificates/1.3/reprocess' => 'api_certificate_requests#reprocess_v1_3',
          :as => :api_certificate_reprocess_v1_3, via: :get
    match '/certificates/1.3/revoke' => 'api_certificate_requests#revoke_v1_3',
          :as => :api_certificate_revoke_v1_3, via: :get
  end

  resource :account, :controller=>:users do
    resource :reseller
  end
  resources :password_resets
  resource :ssl_account do
    get :edit_settings
    put :update_settings
  end

  resources :products

  resources :users do
    collection do
      get :edit_password
      get :edit_email
      get :resend_activation
      get :activation_notice
      get :search
      get :cancel_reseller_signup
    end

    member do
      get :edit_password
      get :edit_email
      get :login_as
      put :admin_update
      get :admin_show
      get :dup_info
      post :consolidate
      get :adjust_funds
      get :change_login
    end
  end

  constraints DomainConstraint.new(Reseller::SUBDOMAIN) do
    resources :resellers, :only=>[:index,:new] do
      collection do
        get :details
        get :restful_api
      end
    end
  end


  resources :affiliates do
    collection do
      get :details
    end

    member do
      get :links
      get :sales
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
      get :order_by_csr
      get :incomplete
      get :reprocessing
      get :search
      get :developers
      post :parse_csr
    end

    member do
      put :update_csr
      get :download
      get :developer
      get :download_other
      get :renew
      get :reprocess
      get :auto_renew
      post :start_over
      put :admin_update
      get :change_ext_order_number
    end

    resource :validation do
      post :upload, :send_dcv_email
      get :send_to_ca
      member do
        get :document_upload
      end
    end

    resource :site_seal
  end

  get '/certificate_orders/filter_by/:id' => 'certificate_orders#filter_by', as: :filter_by_certificate_orders
  get '/certificate_orders/filter_by_scope/:id' => 'certificate_orders#filter_by_scope', as: :filter_by_scope_certificate_orders

  resources :certificate_contents do
    resources :contacts, :only=>:index
  end

  resources :csrs do
    resources :signed_certificates do
      member do
        get :server_bundle
        get :pkcs7
        get :whm_zip
        get :nginx
        get :apache_zip
        get :amazon_zip
      end
    end
    collection do
      get :country_codes
    end

    member do
      get :http_dcv_file
      get :verification_check
    end
  end

  resources :other_party_validation_requests, only: [:create, :show]

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

  get '/validation_histories/:id/documents/:style.:extension' =>
    'validation_histories#documents', :as => :validation_document, style: /.+/i

  resources :orders do
    collection do
      get :checkout, action: "new", as: :checkout # this shows the discount code prompt
      get :show_cart
      get :search
      get :visitor_trackings
      post :create_free_ssl, :create_multi_free_ssl, :lookup_discount
    end
    member do
      get :invoice
      get :refund
      get :change_state
    end
  end
  get '/orders/filter_by_state/:id' => 'orders#filter_by_state', as: :filter_by_state_orders

  resources :apis
  resources :billing_profiles
  get '/certificates/pricing', to: "certificates#pricing", as: :certificate_pricing
  resources :certificates do
    collection do
      get :single_domain
      get :wildcard_or_ucc
    end
    member do
      get :buy
      get :buy_renewal
    end
  end

  get '/register/:activation_code' => 'activations#new', :as => :register
  get '/activate/:id' => 'activations#create', :as => :activate
  get 'get_free_ssl' => 'funded_accounts#create_free_ssl', :as => :create_free_ssl
  get 'secure/allocate_funds' => 'funded_accounts#allocate_funds', :as => :allocate_funds
  get 'secure/allocate_funds_for_order/:id' =>
    'funded_accounts#allocate_funds_for_order', :as => :allocate_funds_for_order
  get 'secure/deposit_funds' => 'funded_accounts#deposit_funds', :as => :deposit_funds
  get 'secure/confirm_funds/:id' => 'funded_accounts#confirm_funds', :as => :confirm_funds
  get 'secure/apply_funds' => 'funded_accounts#apply_funds', :as => :apply_funds
  get 'users/new/affiliates' => 'users#new', :as => :affiliate_signup
  get 'affiliates/:affiliate_id/orders' => 'orders#affiliate_orders', :as => :affiliate_orders
  get ':user_id/orders' => 'orders#user_orders', :as => :user_orders
  get '/sitemap.xml' => 'site#sitemap', :as => :sitemap
  get 'reseller' => 'site#reseller', :as => :reseller,
    :constraints => {:subdomain=>Reseller::SUBDOMAIN}
  get '/subject_alternative_name' => 'site#subject_alternative_name', as: :san
  get 'browser_compatibility' => 'site#compatibility', as: :browsers
  get 'acceptable-top-level-domains-tlds-for-ssl-certificates' => 'site#top_level_domains_tlds', as: :tlds
  #get 'paid_cert_orders'=> 'site#paid_cert_orders'
  (Reseller::TARGETED+SiteController::STANDARD_PAGES).each do |i|
    send("get", i=>"site##{i}", :as => i.to_sym)
  end
  get 'certificates/apidocs/apply' => 'restful_api#docs_apply_v1_3', :as => :restful_apidocs_apply
  get 'certificates/apidocs/dcv' => 'restful_api#dcv', :as => :restful_api_dcv

  #took the anchor version out /\w+\/?\z/ but need to test the results of this,
  #specifically the aff code should be the last thing and not followed by other characters
  #that could route this to anything other than an affiliate crediting
  get '*disregard/code/:id'=>'affiliates#refer', id: /\w+\/?/
  get '/code/:id'=>'affiliates#refer', id: /\w+\/?/

  resources :surls, :constraints => {:subdomain=>Surl::SUBDOMAIN}, except: [:index, :show]
  get '/surls/:id' => 'surls#destroy', :constraints => {:subdomain=>Surl::SUBDOMAIN}
  get '/surls/status_204' => 'surls#status_204', :constraints => {:subdomain=>Surl::SUBDOMAIN}
  post '/surls/login/:id' => 'surls#login', as: :surl_login, :constraints => {:subdomain=>Surl::SUBDOMAIN}
  get '/ssl_links_disclaimer'=>'surls#disclaimer', as: :ssl_links_disclaimer, :constraints => {:subdomain=>Surl::SUBDOMAIN}
  #get ':id'=>'surls#show', id: /[0-9a-z]+/i

  get '/:controller(/:action(/:id))'
  #get "*path" => redirect("/?utm_source=any&utm_medium=any&utm_campaign=404_error")

  get "paypal_express/checkout"
  get "paypal_express/review"
  get "paypal_express/purchase"
end
