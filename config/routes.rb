# frozen_string_literal: true

require 'domain_constraint'

SslCom::Application.routes.draw do
  mount Rswag::Ui::Engine => '/api'
  mount Delayed::Web::Engine, at: '/jobs'
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  resources :apidocs, only: [:index]

  resources :oauth_clients

  match '/oauth/test_request',  to: 'oauth#test_request',  as: :test_request, via: %i[get post]

  match '/oauth/token',         to: 'oauth#token',         as: :token, via: %i[get post]

  match '/oauth/access_token',  to: 'oauth#access_token',  as: :access_token, via: %i[get post]

  match '/oauth/request_token', to: 'oauth#request_token', as: :request_token, via: %i[get post]

  match '/oauth/authorize',     to: 'oauth#authorize',     as: :authorize, via: %i[get post]

  match '/oauth',               to: 'oauth#index',         as: :oauth, via: %i[get post]

  match '/' => 'resellers#index', :constraints => { subdomain: Reseller::SUBDOMAIN }, as: 'resellers_root', via: %i[get post]
  match '/' => 'site#index', :as => :root, via: %i[get post]
  match 'login' => 'user_sessions#new', :as => :login, via: %i[get post]
  match 'logout' => 'user_sessions#destroy', :as => :logout, via: %i[get post]
  match '(/team/:ssl_slug)/signed_certificates/:id/revoke' => 'signed_certificates#revoke', as: 'revoke_signed_certificate', via: %i[put post]

  resources :unsubscribes, only: %i[edit update]
  # resources :site_checks
  match 'site_check' => 'site_checks#new', :as => :site_check, via: %i[get post]
  match 'site_checks' => 'site_checks#create', :as => :site_checks, via: %i[get post]
  match 'enterprise_pki_service_agreement' => 'contacts#enterprise_pki_service_agreement', via: :get

  # api: If version is not specified then use the default version in APIConstraint
  constraints DomainConstraint.new((%w[sws.sslpki.com sws.sslpki.local] + Website.domain_contraints).uniq) do
    scope module: :api do
      scope module: :v1, constraints: APIConstraint.new(version: 1), defaults: { format: 'json' } do
        # Users
        match '/users' => 'api_user_requests#create_v1_4', as: :api_user_create_v1_4, via: %i[options post]
        match '/user/:login' => 'api_user_requests#show_v1_4', as: :api_user_show_v1_4, via: %i[options get], login: %r{.+/?}
        match '/users/get_teams' => 'api_user_requests#get_teams_v1_4', as: :api_user_get_teams_v1_4, via: %i[options get], get_teams: %r{.+/?}
        match '/users/set_default_team' => 'api_user_requests#set_default_team_v1_4', as: :api_user_set_default_team_v1_4, via: %i[options put], set_default_team: %r{.+/?}

        # SSL Manager
        match '/ssl_manager' => 'api_ssl_manager_requests#register', as: :api_ssl_manager_register, via: %i[options post]
        match '/ssl_manager/collection' => 'api_ssl_manager_requests#collection', as: :api_ssl_manager_collection, via: %i[options post]
        match '/ssl_managers' => 'api_ssl_manager_requests#delete', as: :api_ssl_managers_delete, via: %i[options delete]
        match '/ssl_managers' => 'api_ssl_manager_requests#index', as: :api_ssl_managers_index, via: %i[options get]
        match '/ssl_manager/collections' => 'api_ssl_manager_requests#collections', as: :api_ssl_managers_collections, via: %i[options get]

        # ACME
        match '/acme/hmac' => 'api_acme_requests#retrieve_hmac', as: :api_acme_retrieve_hmac, via: [:post]
        match '/acme/credentials' => 'api_acme_requests#retrieve_credentials', as: :api_acme_retrieve_credentials, via: [:post]

        # Code Signing.
        match '/generate_certificate' => 'api_certificate_requests#generate_certificate_v1_4', as: :api_certificate_generate_v1_4, via: %i[options post]

        # Teams
        match '/teams/add_contact' => 'teams#add_contact', as: :api_team_add_contact, via: :post
        match '/teams/add_registrant' => 'teams#add_registrant', as: :api_team_add_registrant, via: :post
        match '/teams/add_billing_profile' => 'teams#add_billing_profile', as: :api_team_add_billing_profile, via: :post
        match '/teams/saved_contacts' => 'teams#saved_contacts', as: :api_team_saved_contacts, via: :get
        match '/teams/saved_registrants' => 'teams#saved_registrants', as: :api_team_saved_registrants, via: :get

        # Signed Certificates
        match '/signed_certificates' => 'api_certificate_requests#retrieve_signed_certificates', as: :api_signed_certificates_retrieve, via: [:post]

        # Certificate Enrollment
        match '/certificate_enrollment' => 'api_certificate_requests#certificate_enrollment_order', as: :api_certificate_enrollment, via: :post

        # Certificates
        match '/certificates' => 'api_certificate_requests#create_v1_4', as: :api_certificate_create_v1_4, via: [:post]
        match '/certificate/:ref' => 'api_certificate_requests#update_v1_4', as: :api_certificate_update_v1_4, via: %i[options put patch post], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/replace' => 'api_certificate_requests#replace_v1_4', as: :api_certificate_replace_v1_4, via: %i[options put patch post], ref: /[a-z0-9\-]+/
        match '/certificate/:ref' => 'api_certificate_requests#show_v1_4', as: :api_certificate_show_v1_4, via: %i[options get], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/callback' => 'api_certificate_requests#callback_v1_4', as: :api_certificate_callback_v1_4, via: %i[options put patch post], ref: /[a-z0-9\-]+/

        match '/certificate/:ref/contacts' => 'api_certificate_requests#contacts_v1_4', as: :api_certificate_contacts_v1_4, via: %i[options put patch post], ref: /[a-z0-9\-]+/

        match '/certificate/:ref/detail' => 'api_certificate_requests#detail_v1_4', as: :api_certificate_detail_v1_4, via: %i[options get], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/detail/site_seal' => 'api_certificate_requests#update_site_seal_v1_4', as: :api_certificate_update_site_seal_v1_4, via: %i[options post], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/validation/document_upload' => 'api_certificate_requests#view_upload_v1_4', as: :api_certificate_view_upload_v1_4, via: %i[options get], ref: /[a-z0-9\-]+/
        match '/certificate/:ref/validation/document_upload' => 'api_certificate_requests#upload_v1_4', as: :api_certificate_upload_v1_4, via: %i[options post], ref: /[a-z0-9\-]+/

        match '/certificate/:ref' => 'api_certificate_requests#revoke_v1_4', as: :api_certificate_revoke_v1_4, via: %i[options delete]
        match '/certificates' => 'api_certificate_requests#index_v1_4', as: :api_certificate_index_v1_4, via: [:get]
        match '/certificates/validations/email' => 'api_certificate_requests#dcv_emails_v1_3', as: :api_dcv_emails_v1_4, via: %i[options get]
        match '/certificate/:ref/validations/methods' => 'api_certificate_requests#dcv_methods_v1_4', as: :api_dcv_methods_v1_4, via: %i[options get]
        match '/certificate/:ref/pretest' => 'api_certificate_requests#pretest_v1_4', as: :pretest_v1_4, via: %i[options get]
        match '/certificate/:ref/api_parameters/:api_call' => 'api_certificate_requests#api_parameters_v1_4', as: :api_parameters_v1_4, via: %i[options get]
        match '/scan/:url' => 'api_certificate_requests#scan', as: :api_scan, via: %i[options get], constraints: { url: %r{[^/]+} }
        match '/analyze/:url' => 'api_certificate_requests#analyze', as: :api_analyze, via: %i[options get], constraints: { url: %r{[^/]+} }
        match '/certificates/validations/csr_hash' => 'api_certificate_requests#dcv_methods_csr_hash_v1_4', as: :api_dcv_methods_csr_hash_v1_4, via: %i[options post]
        match '/certificates/1.3/retrieve' => 'api_certificate_requests#retrieve_v1_3', as: :api_certificate_retrieve_v1_3, via: %i[options get]
        match '/certificates/1.3/dcv_emails' => 'api_certificate_requests#dcv_emails_v1_3', as: :api_dcv_emails_v1_3, via: %i[options get post]
        match '/certificates/1.3/dcv_email_resend' => 'api_certificate_requests#dcv_email_resend_v1_3', as: :api_dcv_email_resend_v1_3, via: %i[options get]
        match '/certificates/1.3/reprocess' => 'api_certificate_requests#reprocess_v1_3', as: :api_certificate_reprocess_v1_3, via: %i[options get]
      end
    end
  end

  resources :password_resets, except: [:show]

  resources :products

  constraints DomainConstraint.new(%w[reseller.ssl.com reseller.ssl.local]) do
    resources :resellers, only: %i[index new] do
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
    match '/enrollment/:product/:duration' => 'certificate_enrollment_requests#new', as: 'new_certificate_enrollment_request', via: %i[get post], duration: %r{\d+/?}
    match '/enrollment_links' => 'certificate_enrollment_requests#enrollment_links', as: 'enrollment_links_certificate_enrollment_requests', via: :get

    resources :folders, only: %i[index create update destroy] do
      collection do
        put :reset_to_system
        get :children
      end
      member do
        put :add_certificate_order
        put :add_certificate_orders
      end
    end

    resources :certificate_enrollment_requests, except: %i[edit new update show] do
      member do
        match :reject, via: %i[put post]
      end
    end

    resources :domains, only: %i[index create update destroy] do
      collection do
        match :validate_all, via: %i[get post]
        match :dcv_all_validate, via: %i[get post]
        match :remove_selected, via: %i[get post]
        match :validate_selected, via: %i[get post]
        match :select_csr, via: %i[get post]
        match :validate_against_csr, via: %i[get post]
        get :search
      end
      member do
        match :validation_request, via: %i[get post]
        match :dcv_validate, via: %i[get post]
      end
    end

    resources :invoices, only: %i[index edit update show destroy] do
      member do
        get  :download
        get  :new_payment
        get  :manage_items
        post :make_payment
        put  :remove_item
        put  :add_item
        put  :make_payment_other
        put  :refund_other
        put  :credit
        put  :update_item
        get  :transfer_items
      end
    end

    resource :user_session do
      collection do
        post :user_login
        get  :duo
        post :duo_verify
        get  :duo_verify
      end
    end

    resources :certificate_order_tokens do
      collection do
        post :request_token
      end
    end

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
        get :show_cert_order
        post :validate_issue
        post :switch_from_comodo
        match :parse_csr, via: %i[post options]
        match :smime_client_enrollment, via: %i[get post]
      end

      member do
        get :update_csr, to: 'application#not_found', status: 404
        match :update_csr, via: %i[put patch]
        match :update_tags, via: %i[put post]
        match :recipient, via: %i[get post]
        get :download
        get :developer
        get :download_other
        get :renew
        get :reprocess
        get :auto_renew
        post :start_over
        get :sslcom_ca
        match :admin_update, via: %i[put patch]
        get :change_ext_order_number
        get :generate_cert
        post :register_domains
        get :attestation
        post :save_attestation
        post :remove_attestation
      end

      resource :validation do
        post :upload, :send_dcv_email
        match :send_to_ca, via: %i[get post]
        post :get_asynch_domains
        post :remove_domains
        post :get_email_addresses
        post :send_callback
        post :add_super_user_email
        post :request_approve_phone_number
        post :cancel_validation_process

        member do
          match :dcv_validate, via: %i[get post options]
          get :document_upload
        end
      end

      resource :site_seal
    end

    resources :certificate_contents do
      resources :attestation_certificates do
        member do
          get :server_bundle
          get :pkcs7
          get :whm_zip
          get :nginx
          get :apache_zip
          get :amazon_zip
          get :download
        end
      end
      resources :contacts, only: :index
      match :update_tags, via: %i[put post], on: :member
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
          get :download
        end
      end
      collection do
        get :country_codes
        post :all_domains
        post :check_validation
      end

      member do
        get :http_dcv_file
        get :verification_check
        post :create_new_unique_value
      end
    end

    resources :managed_csrs do
      collection do
        get :show_csr_detail
        post :add_generated_csr
        post :remove_managed_csrs
      end
    end

    resources :notification_groups do
      resources :scan_logs, only: :index

      collection do
        get :certificate_orders_domains_contacts
        get :search
        post :register_notification_group
        post :remove_groups
        post :scan_groups
        post :scan_individual_group
        post :change_status_groups
        post :check_duplicate
      end
    end

    resources :registered_agents do
      collection do
        post :search
        post :remove_agents
        post :approve_ssl_managers
        post :approve_ssl_manager
      end

      member do
        get :managed_certificates
        post :search_managed_certificates
        post :remove_managed_certificates
      end
    end

    resources :other_party_validation_requests, only: %i[create show]

    resources :validation_histories
    resources :validations, only: %i[index update] do
      collection do
        get :search, :requirements, :domain_control, :ev, :organization
        post :upload_for_registrant
      end
    end
    resources :site_seals, only: %i[index update admin_update] do
      collection do
        get :details
        get :search
      end
      member do
        get :site_report
        get :artifacts
        match :admin_update, via: %i[put patch]
      end
    end

    resources :orders do
      collection do
        get :checkout, action: 'new' # this shows the discount code prompt
        get :show_cart
        post :add_cart
        get :search
        get :visitor_trackings
        post :create_free_ssl
        post :create_multi_free_ssl
        post :lookup_discount
        post :smime_client_enroll_create
        post :ucc_domains_adjust_create
        post :change_quantity_in_cart
      end
      member do
        get :invoice
        get :refund
        get :revoke
        get :change_state
        get :refund_merchant
        match :update_invoice, via: %i[put post]
        match :transfer_order, via: %i[put post]
        match :update_tags, via: %i[put post]
      end
    end
    resources :billing_profiles

    resource :ssl_account do
      get :edit_settings
      get :validate_ssl_slug
      match :update_settings, via: %i[put patch]
      match :update_ssl_slug, via: %i[put patch]
      match :update_company_name, via: %i[put patch]
      collection do
        post :register_u2f
        post :remove_u2f
        post :register_duo
        put  :duo_enable
        put  :duo_own_used
        put  :set_2fa_type
        post :remove_reseller
        post :manage_reseller
      end
      member do
        get :adjust_funds
      end
    end

    resources :users, only: :index do
      match :enable_disable, via: %i[put patch], on: :member
      match :enable_disable_duo, via: %i[put patch], on: :member
    end

    resources :api_credentials do
      member do
        patch 'update_roles'
        get   'remove'
      end
    end

    resource :api_credential do
      collection do
        post :reset_credential
      end
    end

    resource :account, controller: :users do
      resource :reseller
    end

    resources :managed_users, only: %i[new create edit] do
      member do
        patch 'update_roles'
        get   'remove_from_account'
      end
    end

    resources :cdns do
      post :register_account, on: :collection
      # post :register_api_key, on: :collection
      delete :delete_resources, on: :collection
      get :check_cname, on: :collection

      member do
        get :resource_cdn
        patch :update_resource
        post :add_custom_domain
        post :update_custom_domain
        post :update_advanced_setting
        delete :delete_resource
        delete :purge_cache
        post :update_cache_expiry
      end
    end

    get '/orders/filter_by_state/:id' => 'orders#filter_by_state', as: :filter_by_state_orders
    match '/validation_histories/:id/documents/:style.:extension' => 'validation_histories#documents', :as => :validation_document, style: /.+/i, via: %i[get post]
    get 'certificate_orders/filter_by/:id' => 'certificate_orders#filter_by', as: :filter_by_certificate_orders
    get 'certificate_orders/filter_by_scope/:id' => 'certificate_orders#filter_by_scope', as: :filter_by_scope_certificate_orders
    match 'get_free_ssl' => 'funded_accounts#create_free_ssl', :as => :create_free_ssl, via: %i[get post]
    match 'secure/allocate_funds' => 'funded_accounts#allocate_funds', :as => :allocate_funds, via: %i[get post]
    match 'secure/allocate_funds_for_order/:id' => 'funded_accounts#allocate_funds_for_order', :as => :allocate_funds_for_order, via: %i[get post]
    match 'secure/deposit_funds' => 'funded_accounts#deposit_funds', :as => :deposit_funds, via: %i[get put patch post]
    match 'secure/confirm_funds/:id' => 'funded_accounts#confirm_funds', :as => :confirm_funds, via: %i[get post]
    match 'secure/apply_funds' => 'funded_accounts#apply_funds', :as => :apply_funds, via: %i[get post put]
    match 'users/new/affiliates' => 'users#new', :as => :affiliate_signup, via: %i[get post]
    match 'affiliates/:affiliate_id/orders' => 'orders#affiliate_orders', :as => :affiliate_orders, via: %i[get post]
    match ':user_id/orders' => 'orders#user_orders', :as => :user_orders, via: %i[get post]

    match 'paypal_express/checkout', via: %i[get post]
    match 'paypal_express/review', via: %i[get post]
    match 'paypal_express/purchase', via: %i[get post]

    match "/site_seals/:id/site_report'," => 'site_seals#site_report', via: :get

    # mailbox
    get 'mail/inbox' => 'mailbox#inbox', as: :mail_inbox
    get 'mail/sent' => 'mailbox#sent', as: :mail_sent
    get 'mail/trash' => 'mailbox#trash', as: :mail_trash
    match 'mail/compose' => 'mailbox#compose', as: :mail_compose, via: %i[get post]
    get 'mail/read' => 'mailbox#read', as: :mail_read
    put 'mail/reply' => 'mailbox#reply', as: :mail_reply
    put 'mail/move_to_trash' => 'mailbox#move_to_trash', as: :mail_move_to_trash
  end

  scope '(/team/:ssl_slug)', module: false do
    concerns :teamable
  end

  resources :users, except: :index do
    collection do
      get :edit_password
      get :edit_email
      match :resend_activation, via: %i[get post]
      get :activation_notice
      get :search
      get :cancel_reseller_signup
      match :enable_disable, via: %i[put patch]
      match :enable_disable_duo, via: %i[put patch]
      get :show_user
      get :reset_failed_login_count
      put :upload_avatar, format: /(js|json)/
    end

    member do
      get   :edit_password
      get   :edit_email
      get   :login_as
      match :admin_update, via: %i[put patch]
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
      get   :search_teams
      match :create_team, via: %i[get post]
      put   :set_default_team
      match :set_default_team_max, via: %i[put patch]
      match :admin_activate, via: %i[put patch]
      get   :leave_team
      get   :dont_show_again
      get   :duo
      match :duo_verify, via: %i[get post]
      get   :archive_team
      get   :retrieve_team
    end
  end

  resources :apis
  match '/certificates/pricing', to: 'certificates#pricing', as: :certificate_pricing, via: %i[get post]
  resources :certificates do
    collection do
      get :single_domain
      get :wildcard_or_ucc
      get :admin_index
    end
    member do
      get :buy
      get :buy_renewal
      match :manage_product_variants, via: %i[get post]
    end
  end

  match '/contacts/:id/admin_update' => 'contacts#admin_update', as: :admin_update_contact, via: %i[put post]
  match '/ssl_manager/:id/approve' => 'registered_agents#approve', :as => :approve_ssl_manager, via: [:get]
  match '/activate/:id' => 'activations#create', :as => :activate, via: %i[get post]
  match '/register/:activation_code' => 'activations#new', :as => :register, via: %i[get post]
  match '/sitemap.xml' => 'site#sitemap', :as => :sitemap, via: %i[get post]
  match 'reseller' => 'site#reseller', :as => :reseller, :constraints => { subdomain: Reseller::SUBDOMAIN }, via: %i[get post]
  match '/subject_alternative_name' => 'site#subject_alternative_name', as: :san, via: %i[get post]
  match 'browser_compatibility' => 'site#compatibility', as: :browsers, via: %i[get post]
  match 'acceptable-top-level-domains-tlds-for-ssl-certificates' => 'site#top_level_domains_tlds', as: :tlds, via: %i[get post]
  match '/certificate_order_token/:token/generate_cert' => 'certificate_orders#generate_cert', :as => :confirm, via: [:get]
  match '/download_certificates/:co_ids' => 'certificate_orders#download_certificates', as: :download_certificates, via: [:post], defaults: { format: :csv }
  match '/validation/email_verification_check' => 'validations#email_verification_check', :as => :email_verification_check, via: [:post]

  # Callback
  match '/callback/:token' => 'validations#verification', :as => :email_verification, via: [:get]
  match '/validation/automated_call' => 'validations#automated_call', :as => :automated_call, via: [:post]
  match '/validation/phone_verification_check' => 'validations#phone_verification_check', :as => :phone_verification_check, via: [:post]
  match '/validation/register_callback' => 'validations#register_callback', :as => :register_callback, via: [:post]

  # Test Attestation
  match '/verify-attestation' => 'attestation_certificates#verify_attestation', :as => :verify_attestation, via: [:get]
  match '/check-attestation-verification' => 'attestation_certificates#check_attestation_verification', :as => :check_attestation_verification, via: [:post]

  # match 'paid_cert_orders'=> 'site#paid_cert_orders'
  (Reseller::TARGETED + SiteController::STANDARD_PAGES).each do |i|
    send('get', i => "site##{i}", :as => i.to_sym)
  end
  match 'certificates/apidocs/apply' => 'restful_api#docs_apply_v1_3', :as => :restful_apidocs_apply, via: %i[get post]
  match 'certificates/apidocs/dcv' => 'restful_api#dcv', :as => :restful_api_dcv, via: %i[get post]

  # took the anchor version out /\w+\/?\z/ but need to test the results of this,
  # specifically the aff code should be the last thing and not followed by other characters
  # that could route this to anything other than an affiliate crediting
  get '*disregard/code/:id' => 'affiliates#refer', id: %r{\w+/?}
  get '/code/:id' => 'affiliates#refer', id: %r{\w+/?}

  resources :surls, constraints: { subdomain: Surl::SUBDOMAIN }, except: %i[index show]
  get '/surls/:id' => 'surls#destroy', :constraints => { subdomain: Surl::SUBDOMAIN }
  get '/surls/status_204' => 'surls#status_204', :constraints => { subdomain: Surl::SUBDOMAIN }
  post '/surls/login/:id' => 'surls#login', as: :surl_login, :constraints => { subdomain: Surl::SUBDOMAIN }
  get '/ssl_links_disclaimer' => 'surls#disclaimer', as: :ssl_links_disclaimer, :constraints => { subdomain: Surl::SUBDOMAIN }
  # get ':id'=>'surls#show', id: /[0-9a-z]+/i
  match '/:controller(/:action(/:id))', via: %i[get post]
  # match "*path" => redirect("/?utm_source=any&utm_medium=any&utm_campaign=404_error")

  get '/certificate-download' => 'api/v1/api_certificate_requests#download_v1_4'
end

Delayed::Web::Engine.middleware.use Rack::Auth::Basic do |username, password|
  username == '!as09bv#f9' && password == 'a$gdP12@_'
end
