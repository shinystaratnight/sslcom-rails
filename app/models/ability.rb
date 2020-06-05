class Ability
  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    @user = user || User.new # guest user (not logged in)
    @user.roles.each { |role| send(role.name) if Ability.method_defined?(role.name) }

    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    can do |action, subject_class, subject|
      @user.permissions.find_all_by_action(aliases_for_action(action.to_s)).any? do |permission|
        permission.subject_class == subject_class.to_s &&
          (subject.nil? || permission.subject_id.nil? || permission.subject_id == subject.id)
      end
    end
    can :manage, :all if @user.has_role? :admin
  end

  def certificates_requestor
    can :create, CertificateOrder, ssl_account_id: @user.ssl_account_id
    can :delete, CertificateOrder, ssl_account_id: @user.ssl_account_id
    can :update, CertificateOrder, ssl_account_id: @user.ssl_account_id
    can :view, CertificateOrder, ssl_account_id: @user.ssl_account_id
    can :validate_certificate, CertificateOrder, ssl_account_id: @user.ssl_account_id
  end

  def certificates_approver
    can :approve, CertificateOrder, ssl_account_id: @user.ssl_account_id
  end

  def certificates_manager
    certificates_requestor
    certificates_approver
    can :manage, CertificateOrder, ssl_account_id: @user.ssl_account_id
  end

  # for technical or other ppl where prices do not have to be shown
  def prices_restricted
    cannot :view_price, Order, id: @user.ssl_account.order_ids
  end

  def orders_requestor
    can :create, Order, id: @user.ssl_account.order_ids
    can :view, Order, id: @user.ssl_account.order_ids
  end

  def orders_approver
    can :approve, Order, id: @user.ssl_account.order_ids
  end

  def orders_manager
    orders_requestor
    orders_approver
    can :manage, Order, id: @user.ssl_account.order_ids
  end

  def developer
    can :develop, CertificateOrder
  end

  def admin
    certificates_manager
    can :manage, Bill
  end
end
