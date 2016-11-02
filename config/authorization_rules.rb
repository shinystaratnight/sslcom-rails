authorization do
  role :super_user do
    includes :sysadmin
  end

  role :sysadmin do
    includes :vetter
    has_permission_on :users, :to => :admin_manage
    has_permission_on :surls, :to => :manage
  end

  role :vetter do
    has_permission_on :orders, :to => :manage
    has_permission_on :certificate_orders, :to => :manage
    has_permission_on :csrs, :to => :manage
    has_permission_on :signed_certificates, :to => :manage
    has_permission_on :ssl_accounts, :to => [:create, :read, :update]
    has_permission_on :resellers, :to => [:create, :read, :update]
    has_permission_on :affiliates, :to => :manage
    has_permission_on :users, :to => :admin_manage
    has_permission_on :site_seals, :to => :admin_manage, :except=>:delete
    has_permission_on :validations, :validation_histories, :to => :admin_manage
    has_permission_on :validation_rules, :to => :admin_manage, :except=>:delete
  end

  role :account_admin do
    includes :reseller
  end
  
  role :reseller do
    has_permission_on :billing_profiles, :to => :manage do
      if_attribute :ssl_account => is {user.ssl_account}
    end
    has_permission_on :orders, :certificate_orders, :to => [:create]
    has_permission_on :certificate_orders, :to => [:read, :update, :delete] do
      if_attribute ssl_account: is {user.ssl_account}
    end
    has_permission_on :orders, :to => [:read, :update, :delete, :create_free_ssl, :create_multi_free_ssl] do
      if_attribute :billable => is {user.ssl_account}
    end
    has_permission_on :site_seals, :certificate_contents, :to => [:read, :update] do
      if_permitted_to :update, :certificate_order
    end
    has_permission_on :validations, :to => [:read, :update] do
      if_attribute :certificate_orders => {
            :ssl_account => is {user.ssl_account}}
    end
    has_permission_on :validations, :site_seals, :to => [:create]
    has_permission_on :validation_histories, :to => :manage, :except=>:delete do
      if_attribute :validation => {:certificate_order => {
            :ssl_account => is {user.ssl_account}}}
    end
    has_permission_on :csrs, :to => :create
    has_permission_on :csrs, :to => [:update, :delete] do
      if_permitted_to :update, :certificate_content
    end
    has_permission_on :signed_certificates, :to => [:show] do
      if_attribute :csr => {:certificate_content => {:certificate_order => {
            :ssl_account => is {user.ssl_account}}}}
    end
    has_permission_on :ssl_accounts, :to => [:create, :read, :update] do
      if_attribute :id => is {user.ssl_account.id}
    end
    has_permission_on :resellers, :to => [:create, :read, :update] do
      if_attribute :ssl_account => is {user.ssl_account}
    end
    has_permission_on :affiliates, :to => [:create, :read, :update] do
      if_attribute :ssl_account => is {user.ssl_account}
    end
    has_permission_on :users, :to => [:create, :show, :update] do
      if_attribute :id => is {user.id}
    end
    has_permission_on :surls, :to => [:update, :delete] do
      if_attribute :user => is {user}
    end
    has_permission_on :other_party_validation_requests, :to => [:create, :show]
    has_permission_on :surls, :to => [:create, :read]
    has_permission_on :certificates, :to => :read
    has_permission_on :funded_accounts, :to => [:create, :create_free_ssl, :read, :update,
      :allocate_funds, :allocate_funds_for_order, :deposit_funds, :apply_funds,
      :confirm_funds] do
      if_attribute :ssl_account => is {user.ssl_account}
    end
  end

  role :guest do
    has_permission_on :orders, :to => [:show_cart, :create_free_ssl, :create_multi_free_ssl,
                                       :allocate_funds_for_order, :lookup_discount]
    has_permission_on :csrs, :certificate_orders, :orders, :to => :create
    has_permission_on :users, :ssl_accounts, :resellers, :to =>
      [:create, :update]
    has_permission_on :surls, :to => [:create, :read]
    has_permission_on :certificates, :to => :read
    has_permission_on :funded_accounts, :to => [:create, :create_free_ssl, :create_multi_free_ssl,
                                                :allocate_funds_for_order]
    has_permission_on :validations, :site_seals, :to => [:create, :read]
    has_permission_on :validation_histories, :to => [:read]
  end
end

privileges do
  privilege :admin_manage, :includes => [:manage, :admin_update, :admin_show,
    :manage_all, :login_as, :search, :admin_index, :adjust_funds, :change_login, :change_ext_order_number]
  privilege :manage, :includes => [:create, :read, :update, :delete, :refund, :change_state]
  privilege :read, :includes => [:index, :show, :search, :show_cart, :lookup_discount, :invoice]
  privilege :create, :includes => :new
  privilege :update, :includes => [:edit, :edit_update, :edit_email, :verification_check]
  privilege :delete, :includes => :destroy
end
