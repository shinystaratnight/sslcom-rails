require 'apis/certificates_api_app'
require 'domain_constraint'

SslCom::Application.routes.draw do
  resources :cdns, except: [:new, :edit]
  resources :oauth_clients

  match '/oauth/test_request',  :to => 'oauth#test_request',  :as => :test_request, via: [:get, :post]

  match '/oauth/token',         :to => 'oauth#token',         :as => :token, via: [:get, :post]

  match '/oauth/access_token',  :to => 'oauth#access_token',  :as => :access_token, via: [:get, :post]

  match '/oauth/request_token', :to => 'oauth#request_token', :as => :request_token, via: [:get, :post]

  match '/oauth/authorize',     :to => 'oauth#authorize',     :as => :authorize, via: [:get, :post]

  match '/oauth',               :to => 'oauth#index',         :as => :oauth, via: [:get, :post]

  match ''=>'surls#index', :constraints => {:subdomain=>Surl::SUBDOMAIN}, as: 'surls_root', via: [:get, :post]
  match '/'=>'resellers#index', :constraints => {:subdomain=>Reseller::SUBDOMAIN}, as: 'resellers_root', via: [:get, :post]
  match '/' => 'site#index', :as => :root, via: [:get, :post]
  match 'login' => 'user_sessions#new', :as => :login, via: [:get, :post]
  match 'logout' => 'user_sessions#destroy', :as => :logout, via: [:get, :post]

  resources :unsubscribes, only: [:edit, :update]
  #resources :site_checks
  match 'site_check' => 'site_checks#new', :as => :site_check, via: [:get, :post]
  match 'site_checks' => 'site_checks#create', :as => :site_checks, via: [:get, :post]

  # api: If version is not specified then use the default version in APIConstraint
  constraints DomainConstraint.new(
    (%w(sws.sslpki.com sws.sslpki.local)+Website.pluck(:api_host)+Sandbox.pluck(:host)).uniq
  ) do
    scope module: :api do
      scope module: :v1, constraints: APIConstraint.new(version: 1) do
        # Users
        match '/users' => 'api_user_requests#create_v1_4',
          as: :api_user_create_v1_4, via: [:options, :post]
        match '/user/:login' => 'api_user_requests#show_v1_4',
          as: :api_user_show_v1_4, via: [:options, :get], login: /.+\/?/
        
        # Teams
        match '/teams/add_contact' => 'teams#add_contact',
          as: :api_team_add_contact, via: :post
        match '/teams/add_registrant' => 'teams#add_registrant',
          as: :api_team_add_registrant, via: :post
        match '/teams/add_billing_profile' => 'teams#add_billing_profile',
          as: :api_team_add_billing_profile, via: :post
        match '/teams/saved_contacts' => 'teams#saved_contacts',
          as: :api_team_saved_contacts, via: :get
        match '/teams/saved_registrants' => 'teams#saved_registrants',
          as: :api_team_saved_registrants, via: :get
            
        # Certificates
        match '/certificates' => 'api_certificate_requests#create_v1_4',
          as: :api_certificate_create_v1_4, via: [:options, :post]
        match '/certificate/:ref' => 'api_certificate_requests#update_v1_4',
          as: :api_certificate_update_v1_4, via: [:options, :put, :patch, :post], ref: /[a-z0-9\-]+/
        match '/certificate/:ref' => 'api_certificate_requests#show_v1_4',
          as: :api_certificate_show_v1_4, via: [:options, :get], ref: /[a-z0-9\-]+/
        
        match '/certificate/:ref/contacts' => 'api_certificate_requests#contacts_v1_4',
          as: :api_certificate_contacts_v1_4, via: [:options, :put, :patch, :post], ref: /[a-z0-9\-]+/

        match '/certificate/:ref/detail' => 'api_certificate_requests#detail_v1_4',
              as: :api_certificate_detail_v1_4, via: [:options, :get], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/detail/site_seal' => 'api_certificate_requests#update_site_seal_v1_4',
              as: :api_certificate_update_site_seal_v1_4, via: [:options, :post], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/validation/document_upload' => 'api_certificate_requests#view_upload_v1_4',
              as: :api_certificate_view_upload_v1_4, via: [:options, :get], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/validation/document_upload' => 'api_certificate_requests#upload_v1_4',
              as: :api_certificate_upload_v1_4, via: [:options, :post], ref: /[a-z0-9\-]+/

        match '/certificate/:ref' => 'api_certificate_requests#revoke_v1_4',
          as: :api_certificate_revoke_v1_4, via: [:options, :delete]
        match '/certificates/' => 'api_certificate_requests#index_v1_4',
          as: :api_certificate_index_v1_4, via: [:options, :get, :post]
        match '/certificates/validations/email' => 'api_certificate_requests#dcv_emails_v1_3',
          as: :api_dcv_emails_v1_4, via: [:options, :get]
        match '/certificate/:ref/validations/methods' => 'api_certificate_requests#dcv_methods_v1_4',
          as: :api_dcv_methods_v1_4, via: [:options, :get]
        match '/certificate/:ref/pretest' => 'api_certificate_requests#pretest_v1_4',
              as: :pretest_v1_4, via: [:options, :get]
        match '/certificate/:ref/api_parameters/:api_call' => 'api_certificate_requests#api_parameters_v1_4',
          as: :api_parameters_v1_4, via: [:options, :get]
        match '/scan/:url' => 'api_certificate_requests#scan',
          as: :api_scan, via: [:options, :get], constraints: { :url => /[^\/]+/ }
        match '/analyze/:url' => 'api_certificate_requests#analyze',
          as: :api_analyze, via: [:options, :get], constraints: { url: /[^\/]+/ }
        match '/certificates/validations/csr_hash' => 'api_certificate_requests#dcv_methods_csr_hash_v1_4',
          as: :api_dcv_methods_csr_hash_v1_4, via: [:options, :post]
        match '/certificates/1.3/retrieve' => 'api_certificate_requests#retrieve_v1_3',
          as: :api_certificate_retrieve_v1_3, via: [:options, :get]
        match '/certificates/1.3/dcv_emails' => 'api_certificate_requests#dcv_emails_v1_3',
          as: :api_dcv_emails_v1_3, via: [:options, :get, :post]
        match '/certificates/1.3/dcv_email_resend' => 'api_certificate_requests#dcv_email_resend_v1_3',
          as: :api_dcv_email_resend_v1_3, via: [:options, :get]
        match '/certificates/1.3/reprocess' => 'api_certificate_requests#reprocess_v1_3',
          as: :api_certificate_reprocess_v1_3, via: [:options, :get]
      end
    end
  end

  resources :password_resets, except: [:show]

  resources :products

  constraints DomainConstraint.new(%w(reseller.ssl.com reseller.ssl.local)) do
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

  concern :teamable do
    resource :user_session
    resources :certificate_orders do
      resources :physical_tokens do
        member do
          get :activate
        end
      end
      collection do
        get :credits
        get :pending
        get :order_by_csr
        get :incomplete
        get :reprocessing
        get :search
        get :developers
        match :parse_csr, via: [:post, :options]
      end

      member do
        get :update_csr, to: 'application#not_found', status: 404
        match :update_csr, via: [:put, :patch]
        get :download
        get :developer
        get :download_other
        get :renew
        get :reprocess
        get :auto_renew
        post :start_over
        get :sslcom_ca
        match :admin_update, via: [:put, :patch]
        get :change_ext_order_number
      end

      resource :validation do
        post :upload, :send_dcv_email
        match :send_to_ca, via: [:get, :post]
        member do
          get :document_upload
        end
      end

      resource :site_seal
    end

    resources :certificate_contents do
      resources :contacts, only: :index
    end
    
    resources :contacts, except: :index do
      collection do
        get :saved_contacts
      end
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
        match :admin_update, via: [:put, :patch]
      end
    end

    resources :orders do
      collection do
        get :checkout, action: "new" # this shows the discount code prompt
        get :show_cart
        get :search
        get :visitor_trackings
        post :create_free_ssl, :create_multi_free_ssl, :lookup_discount
      end
      member do
        get :invoice
        get :refund
        get :change_state
        get :refund_merchant
        match :update_invoice, via: [:put, :post]
      end
    end
    resources :billing_profiles

    resource :ssl_account do
      get :edit_settings
      get :validate_ssl_slug
      match :update_settings, via: [:put, :patch]
      match :update_ssl_slug, via: [:put, :patch]
      match :update_company_name, via: [:put, :patch]
      member do
        get :adjust_funds
      end
    end

    resources :users, only: :index do
      match :enable_disable, via: [:put, :patch], on: :member
    end

    resource :account, controller: :users do
      resource :reseller
    end

    resources :managed_users, only: [:new, :create, :edit] do
      member do
        patch 'update_roles'
        get   'remove_from_account'
      end
    end

    get '/orders/filter_by_state/:id' => 'orders#filter_by_state', as: :filter_by_state_orders
    match '/validation_histories/:id/documents/:style.:extension' =>
              'validation_histories#documents', :as => :validation_document, style: /.+/i, via: [:get, :post]
    get 'certificate_orders/filter_by/:id' => 'certificate_orders#filter_by', as: :filter_by_certificate_orders
    get 'certificate_orders/filter_by_scope/:id' => 'certificate_orders#filter_by_scope', as: :filter_by_scope_certificate_orders
    match 'get_free_ssl' => 'funded_accounts#create_free_ssl', :as => :create_free_ssl, via: [:get, :post]
    match 'secure/allocate_funds' => 'funded_accounts#allocate_funds', :as => :allocate_funds, via: [:get, :post]
    match 'secure/allocate_funds_for_order/:id' =>
              'funded_accounts#allocate_funds_for_order', :as => :allocate_funds_for_order, via: [:get, :post]
    match 'secure/deposit_funds' => 'funded_accounts#deposit_funds', :as => :deposit_funds, via: [:get, :put, :patch, :post]
    match 'secure/confirm_funds/:id' => 'funded_accounts#confirm_funds', :as => :confirm_funds, via: [:get, :post]
    match 'secure/apply_funds' => 'funded_accounts#apply_funds', :as => :apply_funds, via: [:get, :post, :put]
    match 'users/new/affiliates' => 'users#new', :as => :affiliate_signup, via: [:get, :post]
    match 'affiliates/:affiliate_id/orders' => 'orders#affiliate_orders', :as => :affiliate_orders, via: [:get, :post]
    match ':user_id/orders' => 'orders#user_orders', :as => :user_orders, via: [:get, :post]

    match "paypal_express/checkout", via: [:get, :post]
    match "paypal_express/review", via: [:get, :post]
    match "paypal_express/purchase", via: [:get, :post]

    match "/site_seals/:id/site_report'," => 'site_seals#site_report', via: :get
  end

  scope '(/team/:ssl_slug)', module: false do
    concerns :teamable
  end

  resources :cdns do
    post :register_account, on: :collection
    post :register_api_key, on: :collection
    post :update_resources, on: :collection

    member do
      get :resource_setting
      post :update_resource
      post :add_custom_domain
      post :update_custom_domain
      post :update_advanced_setting
      delete :delete_resource
      get :resource_cache
      delete :purge_cache
      post :update_cache_expiry
    end
  end

  resources :users, except: :index do
    collection do
      get :edit_password
      get :edit_email
      match :resend_activation, via: [:get, :post]
      get :activation_notice
      get :search
      get :cancel_reseller_signup
      match :enable_disable, via: [:put, :patch]
    end

    member do
      get   :edit_password
      get   :edit_email
      get   :login_as
      match :admin_update, via: [:put, :patch]
      get   :admin_show
      get   :dup_info
      post  :consolidate
      get   :adjust_funds
      get   :change_login
      get   :switch_default_ssl_account
      get   :approve_account_invite
      get   :resend_account_invite
      get   :decline_account_invite
      get   :teams
      match :create_team, via: [:get, :post]
      put   :set_default_team
      match :set_default_team_max, via: [:put, :patch]
      match :admin_activate, via: [:put, :patch]
      get   :leave_team
      get   :dont_show_again
    end
  end

  resources :apis
  match '/certificates/pricing', to: "certificates#pricing", as: :certificate_pricing, via: [:get, :post]
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

  match '/activate/:id' => 'activations#create', :as => :activate, via: [:get, :post]
  match '/register/:activation_code' => 'activations#new', :as => :register, via: [:get, :post]
  match '/sitemap.xml' => 'site#sitemap', :as => :sitemap, via: [:get, :post]
  match 'reseller' => 'site#reseller', :as => :reseller,
    :constraints => {:subdomain=>Reseller::SUBDOMAIN}, via: [:get, :post]
  match '/subject_alternative_name' => 'site#subject_alternative_name', as: :san, via: [:get, :post]
  match 'browser_compatibility' => 'site#compatibility', as: :browsers, via: [:get, :post]
  match 'acceptable-top-level-domains-tlds-for-ssl-certificates' => 'site#top_level_domains_tlds',
        as: :tlds, via: [:get, :post]
  #match 'paid_cert_orders'=> 'site#paid_cert_orders'
  (Reseller::TARGETED+SiteController::STANDARD_PAGES).each do |i|
    send("get", i=>"site##{i}", :as => i.to_sym)
  end
  match 'certificates/apidocs/apply' => 'restful_api#docs_apply_v1_3', :as => :restful_apidocs_apply, via: [:get, :post]
  match 'certificates/apidocs/dcv' => 'restful_api#dcv', :as => :restful_api_dcv, via: [:get, :post]

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

  match '/:controller(/:action(/:id))', via: [:get, :post]
  #match "*path" => redirect("/?utm_source=any&utm_medium=any&utm_campaign=404_error")

  get '/certificate-download' => 'api/v1/api_certificate_requests#download_v1_4'
end
