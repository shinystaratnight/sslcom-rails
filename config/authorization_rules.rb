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
    has_permission_on :authorization_rules, :to => :read
    has_permission_on :site_seals, :validation_rules,
      :to => :admin_manage, except: :delete
    has_permission_on :affiliates, :certificate_orders, :csrs, :orders, :signed_certificates, :surls,
      :to => :manage
    has_permission_on :managed_users, :ssl_accounts, :validations, :validation_histories,
      :to => :admin_manage
    has_permission_on :resellers,    :to => [:create, :read, :update]
    has_permission_on :ssl_accounts, :to => [
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
    has_permission_on :users, :to => :admin_manage
    has_permission_on :users, :to => :switch_default_ssl_account do
      if_attribute default_ssl_account: is_in {user.ssl_accounts.map(&:id)}
    end
    has_permission_on :users, :to => :decline_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, :to => :approve_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
  end

  # ============================================================================
  # OWNER Role
  # ============================================================================ 
  role :owner do
    includes :base
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
  end

  # ============================================================================
  # ACCOUNT_ADMIN Role
  # ============================================================================ 
  role :account_admin do
    includes :base
  end

  # ============================================================================
  # USER_MANAGER Role
  # ============================================================================
  role :user_manager do
    includes :user
    #
    # SslAccounts
    #
    has_permission_on :ssl_accounts, :to => :validate_ssl_slug
    has_permission_on :ssl_accounts, :to => :update_ssl_slug, join_by: :and do
      if_attribute get_account_owner: is {user},
                   ssl_slug: is {nil}
    end
    has_permission_on :ssl_accounts, :to => [:update_company_name] do
      if_attribute get_account_owner: is {user}
    end
    has_permission_on :ssl_accounts, :to => [:create, :read, :update] do
      if_attribute :id => is {user.ssl_account.id}
    end

    #
    # ManagedUsers
    #
    has_permission_on :managed_users, :to => [
        :read, :create, :update_roles, :edit, :remove_from_account
    ]
    #
    # Users
    #
    has_permission_on :users, :to => [:create, :delete]
  end

  # ============================================================================
  # BILLING Role
  # ============================================================================
  role :billing do
    includes :user
    #
    # BillingProfiles
    #
    has_permission_on :billing_profiles, :to => :manage do
      if_attribute :ssl_account => is {user.ssl_account}
    end
    has_permission_on :billing_profiles, :to => :index do
      if_attribute :ssl_account => is {user.ssl_account}
    end
    #
    # FundedAccounts
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
    ] do
      if_attribute :ssl_account => is {user.ssl_account}
    end

    #
    # Orders
    #
    has_permission_on :orders, :certificate_orders, :to => :create
    has_permission_on :orders, :to => [
        :create_free_ssl,
        :create_multi_free_ssl,
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
    has_permission_on :certificate_orders, :to => [:read, :update, :delete] do
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
    has_permission_on :validations, :to => [:read, :update] do
      if_attribute :ssl_accounts => contains {user.ssl_account}
    end
    has_permission_on :validations, :site_seals, :to => [:create]
    #
    # ValidationHistories
    #
    has_permission_on :validation_histories, :to => :manage, :except=>:delete do
      if_attribute :ssl_accounts => contains {user.ssl_account}
    end
  end

  # ============================================================================
  # RESELLER Role
  # ============================================================================ 
  role :reseller do
    includes :user
    includes :base
  end  

  # ============================================================================
  # BASE Role: inherited by account_admin, owner and reseller
  # ============================================================================ 
  role :base do
    includes :user
    includes :billing
    includes :validations
    includes :installer
    includes :user_manager
    #
    # Users
    #
    has_permission_on :users, :to => :approve_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, :to => :decline_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, :to => :enable_disable do
      if_attribute id: is_in {user.ssl_account.users.map(&:id).uniq}
    end
    has_permission_on :users, :to => [:create, :show, :update] do
      if_attribute :id => is {user.id}
    end
    has_permission_on :users, :to => :switch_default_ssl_account do
      if_attribute default_ssl_account: is_in {user.ssl_accounts.map(&:id)}
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
    has_permission_on :users, :to => [:read, :update, :edit_email, :edit] do
      if_attribute :id => is {user.id}
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
      if_attribute ssl_account: is_in {user.total_teams_owned}
    end
  end

  # ============================================================================
  # GUEST Role
  # ============================================================================ 
  role :guest do
    has_permission_on :csrs, :certificate_orders, :orders,  :to => :create
    has_permission_on :validations, :site_seals, :surls,    :to => [:create, :read]
    has_permission_on :users, :ssl_accounts, :resellers,    :to => [:create, :update]
    has_permission_on :certificates, :validation_histories, :to => :read
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
    :index, :invoice, :lookup_discount, :search, :show, :show_cart
  ]
  privilege :update, includes: [
    :edit, :edit_email, :edit_update, :verification_check
  ]
  privilege :create, includes: :new
  privilege :delete, includes: :destroy
  privilege :admin_manage, includes: [
    :adjust_funds,
    :admin_index,
    :admin_show,
    :admin_update,
    :change_ext_order_number,
    :change_login,
    :edit,
    :edit_settings,
    :enable_disable,
    :login_as,
    :manage,
    :manage_all,
    :remove_from_account,
    :resend_account_invite,
    :search,
    :set_default_team_max,
    :update_company_name,
    :update_roles,
    :update_settings,
    :update_ssl_slug
  ]
end
