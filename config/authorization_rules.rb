authorization do
  # ============================================================================
  # SUPER_USER Role
  # ============================================================================
  role :super_user do
    includes :sysadmin
    has_permission_on :validations, :certificate_orders, to: :super_user_manage
  end

  # ============================================================================
  # SYSADMIN Role
  # ============================================================================
  role :sysadmin do
    includes :user
    includes :owner
    has_permission_on :certificates, to: %i[admin_index new create]
    has_permission_on :certificates, to: %i[
      edit
      update
      show
      manage_product_variants
      destroy
    ] do
      if_attribute role_can_manage: is_in {user.roles.ids}
    end
    has_permission_on :authorization_rules, to: :read
    has_permission_on :site_seals, :validation_rules, :certificate_orders,
                      to:  :sysadmin_manage, except: :delete
    has_permission_on :affiliates, :certificate_orders, :domains, :cdns, :csrs, :orders, :signed_certificates, :surls, :physical_tokens,
                      to:  :manage
    has_permission_on :managed_users, :ssl_accounts, :validations, :validation_histories,
                      to:  :sysadmin_manage
    has_permission_on :resellers,    to: %i[create read update]
    has_permission_on :orders,       to: %i[refund_merchant update_invoice revoke]
    #
    # Contacts
    #
    has_permission_on :contacts, to: :sysadmin_manage
    #
    # SslAccounts
    #
    has_permission_on :ssl_accounts, to: %i[
      create
      read
      update
      update_company_name
      update_ssl_slug
      validate_ssl_slug
    ]
    #
    # Users
    #
    has_permission_on :users, to:  :sysadmin_manage
    #
    # Invoices
    #
    has_permission_on :invoices, to: %i[
      add_item
      edit
      remove_item
      make_payment_other
      update
      refund_other
      credit
      destroy
      update_item
      manage_items
      transfer_items
    ]
    #
    # Folders
    #
    has_permission_on :folders, to: %i[
      add_certificate_order
      add_certificate_orders
      add_to_folder
      children
      create
      destroy
      index
      reset_to_system
      update
      recipient
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
    has_permission_on :ssl_accounts, to: %i[create update]
    has_permission_on :ssl_accounts, to: :admin_manage do
      if_attribute get_account_owner: is {user}
    end
    #
    # FundedAccounts
    #
    has_permission_on :funded_accounts, to: :create
    #
    # ManagedUsers
    #
    has_permission_on :managed_users, to: %i[
      edit read remove_from_account update_roles
    ], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.cached_users.map(&:id).uniq}
      if_attribute ssl_accounts: contains {user.ssl_account}
    end
    #
    # Users
    #
    has_permission_on :users, to: [:upload_avatar]
  end

  # ============================================================================
  # ACCOUNT_ADMIN Role
  # ============================================================================
  role :account_admin do
    includes :base

    #
    # Contacts: CertificateContact
    #
    has_permission_on :contacts, to: %i[
      edit
      update
      show
    ], join_by: :and do
      if_attribute contactable: is {user.ssl_account}
      if_attribute type: is {'CertificateContact'}
    end
    has_permission_on :contacts, to: :destroy, join_by: :and do
      if_attribute contactable: is {user.ssl_account}
      if_attribute type: is {'CertificateContact'}
      if_attribute saved_default: is {false}
    end
    #
    # Contacts: Registrant
    #
    has_permission_on :contacts, to: [
      :show
    ], join_by: :and do
      if_attribute contactable: is {user.ssl_account}
      if_attribute type: is {'Registrant'}
    end
    has_permission_on :contacts, to: %i[
      destroy
      edit
      update
    ], join_by: :and do
      if_attribute contactable: is {user.ssl_account}
      if_attribute type: is {'Registrant'}
      if_attribute 'validated?' => is {false}
    end
    #
    # SslAccounts
    #
    has_permission_on :ssl_accounts, to: %i[create validate_ssl_slug update]
    has_permission_on :ssl_accounts, to: :update_ssl_slug, join_by: :and do
      if_attribute id: is {user.ssl_account.id},
                   ssl_slug: is {nil}
    end
    has_permission_on :ssl_accounts, to: %i[
      edit_settings
      read
      update
      update_company_name
      update_settings
    ] do
      if_attribute id: is {user.ssl_account.id}
    end
    #
    # FundedAccounts
    #
    has_permission_on :funded_accounts, to: :create
    #
    # ManagedUsers
    #
    has_permission_on :managed_users, to: %i[
      edit read remove_from_account update_roles
    ], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.cached_users.map(&:id).uniq}
      if_attribute total_teams_owned: does_not_contain {user.ssl_account}
    end
    #
    # Users
    #
    has_permission_on :users, to: %i[enable_disable enable_disable_duo delete], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.cached_users.map(&:id).uniq}
      if_attribute total_teams_owned: does_not_contain {user.ssl_account}
    end
    #
    # Folders
    #
    has_permission_on :folders, to: %i[children index create]
    has_permission_on :folders, to: %i[
      add_to_folder
      add_certificate_order
      add_certificate_orders
      destroy
      reset_to_system
      update
    ] do
      if_attribute ssl_account_id: is {user.ssl_account.id}
    end
    #
    # CertificateEnrollmentRequestRequests
    #
    has_permission_on :certificate_enrollment_requests, to: %i[enrollment_links index]
    has_permission_on :certificate_enrollment_requests, to: %i[
      update
      destroy
      reject
    ] do
      if_attribute ssl_account_id: is {user.ssl_account.id}
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
    has_permission_on :managed_users, to: :create
    has_permission_on :managed_users, to: %i[
      edit read remove_from_account update_roles
    ], join_by: :and do
      # cannot on users w/roles account_admin|owner|sysadmin|reseller OR self
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.cached_users.map(&:id).uniq}
      if_attribute total_teams_cannot_manage_users: contains {user.ssl_account}
    end
    #
    # Users
    #
    has_permission_on :users, to: %i[create read]
    has_permission_on :users, to: %i[enable_disable enable_disable_duo delete], join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in  {user.ssl_account.cached_users.map(&:id).uniq}
      if_attribute total_teams_cannot_manage_users: contains {user.ssl_account}
    end
    #
    # FundedAccounts
    #
    has_permission_on :funded_accounts, to: :create
    #
    # SslAccounts
    #
    has_permission_on :ssl_accounts, to: %i[create validate_ssl_slug]
  end

  # ============================================================================
  # BILLING Role
  # ============================================================================
  role :billing do
    includes :user
    #
    # BillingProfiles
    #
    has_permission_on :billing_profiles, to: %i[delete edit read update] do
      if_attribute users_can_manage: contains {user}
    end
    has_permission_on :billing_profiles, to: %i[create index]
    #
    # Invoices
    #
    has_permission_on :invoices, to: :index
    has_permission_on :invoices, to: %i[
      download
      make_payment
      new_payment
      show
    ] do
      if_attribute billable: is {user.ssl_account}
    end
    #
    # FundedAccounts
    #  most routes do not use 'id' in params to denote funded_account id
    #  so attribute_check is not possible.
    #
    has_permission_on :funded_accounts, to: %i[
      create
      create_free_ssl
      read
      update
      allocate_funds
      allocate_funds_for_order
      deposit_funds
      apply_funds
      confirm_funds
    ]
    #
    # CertificateOrders
    #
    has_permission_on :certificate_orders, to: :smime_client_enrollment
    has_permission_on :certificate_orders, to: %i[create read show] do
      if_attribute ssl_account: is {user.ssl_account}
    end
    has_permission_on :certificates, to: [:buy_renewal]
    #
    # Orders
    #
    has_permission_on :orders, to: :transfer_order do
      if_attribute billable: is_in {user.ssl_accounts}
    end
    has_permission_on :orders, to: %i[
      create
      create_free_ssl
      create_multi_free_ssl
      ucc_domains_adjust_create
      smime_client_enroll_create
      delete
      read
      update
    ] do
      if_attribute billable: is {user.ssl_account}
    end
  end

  # ============================================================================
  # INDIVIDUAL_CERTIFICATE Role
  # ============================================================================
  role :individual_certificate do
    includes :user
    includes :validations

    #
    # CertificateOrders
    #
    has_permission_on :certificate_orders, to: %i[
      edit
      delete
      read
      show
      update
    ] do
      if_attribute assignee_id: is {user.id}
    end

    has_permission_on :signed_certificates, to: [:show] do
      if_attribute csr: { certificate_content: { certificate_order: {
        assignee_id: is {user.id}
      } } }
    end

    has_permission_on :physical_tokens, to: [:read] do
      if_attribute certificate_order_id: is_in {
        user.ssl_account.cached_certificate_orders.map(&:id).uniq
      }
    end

    has_permission_on :site_seals, :certificate_contents, to: %i[read update] do
      if_permitted_to :update, :certificate_order
    end
  end

  # ============================================================================
  # INSTALLER Role
  # ============================================================================
  role :installer do
    includes :user
    includes :validations
    #
    # Folders
    #
    has_permission_on :folders, to: %i[
      add_certificate_order
      add_certificate_orders
      add_to_folder
      children
      create
      index
    ] do
      if_attribute ssl_account_id: is {user.ssl_account.id}
    end
    #
    # Csrs
    #
    has_permission_on :csrs, to: %i[create verification_check]
    has_permission_on :csrs, to: %i[update delete] do
      if_permitted_to :update, :certificate_content
    end

    has_permission_on :certificates, to: :read
    #
    # CertificateOrders
    #
    has_permission_on :certificate_orders, to: :smime_client_enrollment
    has_permission_on :certificate_orders, to: %i[
      attestation
      edit
      delete
      read
      show
      update
      recipient
    ] do
      if_attribute ssl_account: is {user.ssl_account}
    end

    has_permission_on :contacts, to: %i[read update delete] do
      if_attribute contactable: is_in {user.ssl_account.certificate_contacts}
    end

    has_permission_on :signed_certificates, to: [:show] do
      if_attribute csr: { certificate_content: { certificate_order: {
        ssl_account: is {user.ssl_account}
      } } }
    end

    has_permission_on :physical_tokens, to: [:read] do
      if_attribute certificate_order_id: is_in {
        user.ssl_account.cached_certificate_orders.map(&:id).uniq
      }
    end

    has_permission_on :site_seals, :certificate_contents, to: %i[read update] do
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
    has_permission_on :validations, to: %i[read update create dcv_validate] do
      if_attribute users: contains {user}
    end
    has_permission_on :validations, to: :upload_for_registrant
    #
    # ValidationHistories
    #
    has_permission_on :validation_histories, to: :manage, except: :delete do
      if_attribute ssl_accounts: contains {user.ssl_account}
    end
    #
    # SiteSeals
    #
    has_permission_on :site_seals, to: %i[create read update]
    #
    # SignedCertificates
    #
    has_permission_on :signed_certificates, to: :revoke
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
    has_permission_on :users, to: :enable_disable, join_by: :and do
      if_attribute id: is_not {user.id}
      if_attribute id: is_in {user.ssl_account.cached_users.map(&:id).uniq}
    end
    has_permission_on :users, to: %i[create show update] do
      if_attribute id: is {user.id}
    end
    has_permission_on :users, to: :create_team do
      if_attribute max_teams_reached?: is {false}
    end
    #
    # Other
    #
    has_permission_on :resellers, to: %i[create read update] do
      if_attribute ssl_account: is {user.ssl_account}
    end
    has_permission_on :affiliates, to: %i[create read update] do
      if_attribute ssl_account: is {user.ssl_account}
    end
    has_permission_on :other_party_validation_requests, to: %i[create show]
  end

  # ============================================================================
  # USER Role: basics permissions inherited by all roles
  # ============================================================================
  role :user do
    #
    # Mailbox
    #
    has_permission_on :mailbox, to: %i[
      inbox
      sent
      trash
      compose
      read
      reply
      move_to_trash
    ] do
      if_attribute messageable: is {user}
    end
    #
    # Users
    #
    has_permission_on :users, to: %i[
      dont_show_again
      edit
      edit_email
      edit_password
      leave_team
      search
      show
      update
    ] do
      if_attribute id: is {user.id}
    end
    has_permission_on :users, to: :index do
      if_attribute can_manage_team_users?: is {true}
    end
    has_permission_on :users, to: :switch_default_ssl_account do
      if_attribute default_ssl_account: is_in {user.ssl_accounts.map(&:id)}
    end
    has_permission_on :users, to: :duo do
      if_attribute default_ssl_account: is_in {user.ssl_accounts.map(&:id)}
    end
    has_permission_on :users, to: :duo_verify do
      if_attribute default_ssl_account: is_in {user.ssl_accounts.map(&:id)}
    end
    has_permission_on :users, to:  :resend_account_invite do
      if_attribute ssl_account_id: is_in {user.ssl_accounts.map(&:id)}
    end
    has_permission_on :users, to: :approve_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, to: :decline_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, to: :set_default_team do
      if_attribute ssl_account: is_in {user.ssl_accounts}
    end
    #
    # U2f
    #
    has_permission_on :u2fs, to: %i[new create]
    has_permission_on :u2fs, to: %i[
      index
      create
      update
      destroy
      verify
    ] do
      if_attribute user_id: is {user.id}
    end
    #
    # CertificateOrder
    #
    has_permission_on :certificate_orders, :certificate_contents, to: :update_tags do
      if_attribute ssl_account_id: is_in {user.ssl_accounts.pluck(:id)}
    end
    #
    # Contacts
    #
    has_permission_on :contacts, to: %i[
      new
      create
      saved_contacts
      enterprise_pki_service_agreement
    ]
    #
    # Orders
    #
    has_permission_on :orders, to: %i[update_invoice update_tags] do
      if_attribute billable_id: is_in {user.ssl_accounts.pluck(:id)}
    end
    #
    # Folders
    #
    has_permission_on :folders, to: %i[children index]
    has_permission_on :folders, to: %i[
      add_to_folder
      add_certificate_order
      add_certificate_orders
    ] do
      if_attribute ssl_account_id: is {user.ssl_account.id}
    end
    #
    # Domains
    #
    has_permission_on :domains, to: [:index]
    #
    # CertificateEnrollmentRequests
    #
    has_permission_on :certificate_enrollment_requests, to: :create
  end

  # ============================================================================
  # GUEST Role
  # ============================================================================
  role :guest do
    has_permission_on :csrs, :certificate_orders, :orders,  to: %i[create smime_client_enrollment lint]
    has_permission_on :certificates, to: :buy_renewal
    has_permission_on :site_seals, to: [:site_report]
    has_permission_on :users, :ssl_accounts, :resellers, to: %i[create update]
    has_permission_on :certificates, to:  :read
    has_permission_on :funded_accounts, to: %i[
      allocate_funds_for_order
      create
      create_free_ssl
      create_multi_free_ssl
    ]
    has_permission_on :orders, to: %i[
      allocate_funds_for_order
      create_free_ssl
      create_multi_free_ssl
      lookup_discount
      show_cart
      add_cart
      change_quantity_in_cart
    ]
    has_permission_on :contacts, to: %i[
      new
      create
      saved_contacts
    ]
    #
    # Users
    #
    has_permission_on :users, to: :approve_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end
    has_permission_on :users, to: :decline_account_invite do
      if_attribute get_approval_tokens: is {user.get_approval_tokens}
    end

    # Ajax
    has_permission_on :certificate_orders, to: :ajax
    has_permission_on :validations, to: :ajax
    #
    # CertificateEnrollmentRequests
    #
    has_permission_on :certificate_enrollment_requests, to: %i[create new enrollment_links]
    has_permission_on :u2fs, to: %i[new create]
  end
end

# ============================================================================
# Privileges: admin_manage, manage, read, update, create and delete
# ============================================================================
privileges do
  privilege :manage, includes: %i[
    change_state create delete read refund update recipient
  ]
  privilege :read, includes: %i[
    index invoice lookup_discount search show show_cart add_cart change_quantity_in_cart developer site_report ajax
  ]
  privilege :update, includes: %i[
    edit edit_email edit_update verification_check
  ]
  privilege :create, includes: %i[new generate_cert]
  privilege :delete, includes: :destroy
  privilege :admin_manage, includes: %i[
    attestation
    admin_index
    admin_show
    admin_update
    edit
    edit_settings
    edit_password
    enable_disable
    manage
    manage_all
    remove_from_account
    resend_account_invite
    search
    update_company_name
    update_settings
    register_duo
    duo_enable
    duo_own_used
    set_2fa_type
    update_ssl_slug
    saved_contacts
    smime_client_enrollment
    manage_reseller
    remove_reseller
  ]
  privilege :sysadmin_manage, includes: %i[
    admin_activate
    admin_manage
    adjust_funds
    change_ext_order_number
    change_login
    login_as
    refund_merchant
    search
    set_default_team_max
    update_roles
    search_teams
    upload_for_registrant
  ]
  privilege :super_user_manage, includes: %i[
    sslcom_ca
    send_to_ca
  ]
end
