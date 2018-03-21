authorization do
  # ============================================================================
  # SUPER_USER Role
  # ============================================================================
  role :super_user do
    includes :sysadmin
  end

  # ============================================================================
  # SYSADMIN Role
  # ============================================================================
  role :sysadmin do
    includes :user
    includes :owner
    has_permission_on :authorization_rules, :to => :read
    has_permission_on :site_seals, :validation_rules, :certificate_orders,
      :to => :sysadmin_manage, except: :delete
    has_permission_on :affiliates, :certificate_orders, :cdns, :csrs, :orders, :signed_certificates, :surls, :physical_tokens,
      :to => :manage
    has_permission_on :managed_users, :ssl_accounts, :validations, :validation_histories,
      :to => :sysadmin_manage
    has_permission_on :resellers,    to: [:create, :read, :update]
    has_permission_on :orders,       to: [:refund_merchant, :update_invoice]
    has_permission_on :ssl_accounts, to: [
      :create,
      :read,
      :update,
      :update_company_name,
      :update_ssl_slug,
      :validate_ssl_slug
    ]
    #
    # Users
    #
    has_permission_on :users, :to => :sysadmin_manage
    #
    # Invoices
    #
    has_permission_on :invoices, to: [
      :add_item,
      :edit,
      :remove_item,
      :make_payment_other,
      :update
    ]
  end

  # ============================================================================
  # OWNER Role
  # ============================================================================ 
  role :owner do
    includes :base
    includes :account_admin
    #
    # SslAccounts
    #
    has_permission_on :ssl_accounts, :to => :create
    has_permission_on :ssl_accounts, :to => :admin_manage do
      if_attribute get_account_owner: is {user}
    end
    #
    # FundedAccounts
    #
    has_permission_on :funded_accounts, :to => :create
    #
    # ManagedUsers
    #
    has_permission_on :managed_users, :to => [
      :edit, :read, :remove_from_account, :update_roles
    ], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.users.map(&:id).uniq}
      if_attribute :ssl_accounts => contains {user.ssl_account}
    end
  end

  # ============================================================================
  # ACCOUNT_ADMIN Role
  # ============================================================================ 
  role :account_admin do
    includes :base
    
    #
    # Contacts
    #
    has_permission_on :contacts, to: [
      :edit,
      :update,
      :show,
      :destroy
    ] do
      if_attribute :contactable_id => is {user.ssl_account.id}
    end
    #
    # SslAccounts
    #
    has_permission_on :ssl_accounts, :to => [:create, :validate_ssl_slug]
    has_permission_on :ssl_accounts, :to => :update_ssl_slug, join_by: :and do
      if_attribute :id => is {user.ssl_account.id},
                   ssl_slug: is {nil}
    end
    has_permission_on :ssl_accounts, :to => [
      :edit_settings,
      :read,
      :update,
      :update_company_name,
      :update_settings
    ] do
      if_attribute :id => is {user.ssl_account.id}
    end
    #
    # FundedAccounts
    #
    has_permission_on :funded_accounts, :to => :create
    #
    # ManagedUsers
    #
    has_permission_on :managed_users, :to => [
      :edit, :read, :remove_from_account, :update_roles
    ], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.users.map(&:id).uniq}
      if_attribute total_teams_owned: does_not_contain {user.ssl_account}
    end
    #
    # Users
    #
    has_permission_on :users, :to => [:enable_disable, :delete], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.users.map(&:id).uniq}
      if_attribute total_teams_owned: does_not_contain {user.ssl_account}
    end
  end

  # ============================================================================
  # USERS_MANAGER Role
  # ============================================================================
  role :users_manager do
    includes :user
    #
    # ManagedUsers
    #
    has_permission_on :managed_users, :to => :create
    has_permission_on :managed_users, :to => [
      :edit, :read, :remove_from_account, :update_roles
    ], join_by: :and do
      # cannot on users w/roles account_admin|owner|sysadmin|reseller OR self
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.users.map(&:id).uniq}
      if_attribute total_teams_cannot_manage_users: contains {user.ssl_account}
    end
    #
    # Users
    #
    has_permission_on :users, :to => [:create, :read]
    has_permission_on :users, :to => [:enable_disable, :delete], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.users.map(&:id).uniq}
      if_attribute total_teams_cannot_manage_users: contains {user.ssl_account}
    end
    #
    # FundedAccounts
    #
    has_permission_on :funded_accounts, :to => :create
    #
    # SslAccounts
    #
    has_permission_on :ssl_accounts, :to => [:create, :validate_ssl_slug]
    #
    # Contacts
    #
    has_permission_on :contacts, to: [
      :edit,
      :update,
      :show,
      :destroy
    ] do
      if_attribute :contactable_id => is {user.ssl_account.id}
    end
  end

  # ============================================================================
  # BILLING Role
  # ============================================================================
  role :billing do
    includes :user
    #
    # BillingProfiles
    #
    has_permission_on :billing_profiles, to: [:delete, :edit, :read, :update] do
      if_attribute :users_can_manage => contains {user}
    end
    has_permission_on :billing_profiles, to: [:create, :index]
    # 
    # Invoices
    # 
    has_permission_on :invoices, to: :index
    has_permission_on :invoices, to: [
      :download,
      :make_payment,
      :new_payment,
      :show
    ] do
      if_attribute billable: is {user.ssl_account}
    end
    #
    # FundedAccounts
    #  most routes do not use 'id' in params to denote funded_account id
    #  so attribute_check is not possible.
    #
    has_permission_on :funded_accounts, :to => [
        :create,
        :create_free_ssl,
        :read,
        :update,
        :allocate_funds,
        :allocate_funds_for_order,
        :deposit_funds,
        :apply_funds,
        :confirm_funds
    ]
    #
    # CertificateOrders
    #
    has_permission_on :certificate_orders, :to => [:create, :read, :show] do
      if_attribute ssl_account: is {user.ssl_account}
    end
    has_permission_on :certificates, :to => [:buy_renewal]
    #
    # Orders
    #
    has_permission_on :orders, :to => [
        :create,
        :create_free_ssl,
        :create_multi_free_ssl,
        :create_reprocess_ucc,
        :delete,
        :read,
        :update
    ] do
      if_attribute :billable => is {user.ssl_account}
    end
  end

  # ============================================================================
  # INSTALLER Role
  # ============================================================================
  role :installer do
    includes :user
    includes :validations
    #
    # Csrs
    #
    has_permission_on :csrs, :to => :create
    has_permission_on :csrs, :to => [:update, :delete] do
      if_permitted_to :update, :certificate_content
    end

    has_permission_on :certificates, :to => :read
    #
    # CertificateOrders
    #
    has_permission_on :certificate_orders, to: [
      :edit,
      :delete,
      :read,
      :show,
      :update
    ] do
      if_attribute ssl_account: is {user.ssl_account}
    end

    has_permission_on :contacts, :to => [:read, :update, :delete] do
      if_attribute :contactable => is_in {user.ssl_account.certificate_contacts}
    end

    has_permission_on :signed_certificates, :to => [:show] do
      if_attribute :csr => {:certificate_content => {:certificate_order => {
          :ssl_account => is {user.ssl_account}}}
      }
    end

    has_permission_on :physical_tokens, :to => [:read] do
      if_attribute certificate_order_id: is_in {user.ssl_account.certificate_orders.map(&:id).uniq
      }
    end

    has_permission_on :site_seals, :certificate_contents, :to => [:read, :update] do
      if_permitted_to :update, :certificate_order
    end
  end

  # ============================================================================
  # VALIDATIONS Role
  # ============================================================================
  role :validations do
    includes :user
    #
    # Validations
    #
    # has_permission_on :validations, :to => [:create]
    has_permission_on :validations, :to => [:read, :update, :create] do
      if_attribute :users => contains {user}
    end
    #
    # ValidationHistories
    #
    has_permission_on :validation_histories, :to => :manage, :except=>:delete do
      if_attribute :ssl_accounts => contains {user.ssl_account}
    end
    #
    # SiteSeals 
    #
    has_permission_on :site_seals, :to => [:create, :read, :update]
  end

  # ============================================================================
  # RESELLER Role
  # ============================================================================ 
  role :reseller do
    includes :base
    includes :owner
  end  

  # ============================================================================
  # BASE Role: inherited by account_admin, owner and reseller
  # ============================================================================ 
  role :base do
    includes :user
    includes :billing
    includes :validations
    includes :installer
    includes :users_manager
    #
    # Users
    #
    has_permission_on :users, :to => :enable_disable, join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in {user.ssl_account.users.map(&:id).uniq}
    end
    has_permission_on :users, :to => [:create, :show, :update] do
      if_attribute :id => is {user.id}
    end
    has_permission_on :users, :to => :create_team do
      if_attribute max_teams_reached?: is {false}
    end
    #
    # Other
    # 
    has_permission_on :resellers, :to => [:create, :read, :update] do
      if_attribute :ssl_account => is {user.ssl_account}
    end
    has_permission_on :affiliates, :to => [:create, :read, :update] do
      if_attribute :ssl_account => is {user.ssl_account}
    end
    has_permission_on :other_party_validation_requests, :to => [:create, :show]
  end

  # ============================================================================
  # USER Role: basics permissions inherited by all roles
  # ============================================================================
  role :user do
    # 
    # Users
    # 
    has_permission_on :users, :to => [
      :dont_show_again,
      :edit,
      :edit_email,
      :edit_password,
      :leave_team,
      :search,
      :show,
      :update
    ] do
      if_attribute :id => is {user.id}
    end
    has_permission_on :users, :to => :index do
      if_attribute :can_manage_team_users? => is {true}
    end
    has_permission_on :users, :to => :switch_default_ssl_account do
      if_attribute default_ssl_account: is_in {user.ssl_accounts.map(&:id)}
    end
    has_permission_on :users, :to => :resend_account_invite do
      if_attribute ssl_account_id: is_in {user.ssl_accounts.map(&:id)}
    end
    has_permission_on :users, :to => :approve_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, :to => :decline_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, :to => :set_default_team do
      if_attribute ssl_account: is_in {user.ssl_accounts}
    end
    # 
    # Contacts
    #
    has_permission_on :contacts, to: [
      :new,
      :create,
      :saved_contacts
    ]
    # 
    # Orders
    #
    has_permission_on :orders, to: :update_invoice do
      if_attribute billable_id: is_in {user.ssl_accounts.pluck(:id)}
    end
  end

  # ============================================================================
  # GUEST Role
  # ============================================================================ 
  role :guest do
    has_permission_on :csrs, :certificate_orders, :orders,  :to => :create
    has_permission_on :certificates,  :to => :buy_renewal
    has_permission_on :site_seals, :to => [:site_report]
    has_permission_on :users, :ssl_accounts, :resellers,    :to => [:create, :update]
    has_permission_on :certificates, :to => :read
    has_permission_on :funded_accounts, :to => [
      :allocate_funds_for_order,
      :create,
      :create_free_ssl,
      :create_multi_free_ssl
    ]
    has_permission_on :orders, :to => [
      :allocate_funds_for_order,
      :create_free_ssl,
      :create_multi_free_ssl, 
      :lookup_discount,
      :show_cart
    ]
    has_permission_on :contacts, to: [
      :new,
      :create,
      :saved_contacts
    ]
    #
    # Users
    # 
    has_permission_on :users, :to => :approve_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, :to => :decline_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
  end
end

# ============================================================================
# Privileges: admin_manage, manage, read, update, create and delete
# ============================================================================ 
privileges do
  privilege :manage, includes: [
    :change_state, :create, :delete, :read, :refund, :update
  ]
  privilege :read, includes: [
    :index, :invoice, :lookup_discount, :search, :show, :show_cart, :developer, :site_report
  ]
  privilege :update, includes: [
    :edit, :edit_email, :edit_update, :verification_check
  ]
  privilege :create, includes: :new
  privilege :delete, includes: :destroy
  privilege :admin_manage, includes: [
    :admin_activate,
    :admin_index,
    :admin_show,
    :admin_update,
    :change_ext_order_number,
    :edit,
    :edit_settings,
    :edit_password,
    :enable_disable,
    :manage,
    :manage_all,
    :remove_from_account,
    :resend_account_invite,
    :search,
    :update_company_name,
    :update_settings,
    :update_ssl_slug
  ]
  privilege :sysadmin_manage, includes: [
    :admin_manage,
    :adjust_funds,
    :change_ext_order_number,
    :change_login,
    :login_as,
    :refund_merchant,
    :search,
    :set_default_team_max,
    :sslcom_ca,
    :update_roles
  ]
end
