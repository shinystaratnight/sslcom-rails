class SslAccount < ActiveRecord::Base
  extend Memoist
  using_access_control
  acts_as_billable
  easy_roles :roles
  has_many   :api_credentials
  has_one   :duo_account
  has_many  :billing_profiles
  has_many  :certificate_orders, -> { unscope(where: [:workflow_state, :is_expired]).includes([:orders]) },
            before_add: Proc.new { |p, d|
                folder=Folder.find_by(default: true, ssl_account_id: p.id)
                d.folder_id= folder.id unless folder.blank?
            } do
    def current
      where{workflow_state >>['new']}.first
    end

    def expired
      joins(:signed_certificates).group("certificate_orders.id").having("max(signed_certificates.expiration_date) < ?", Date.today)
    end

    def revoked
      joins{signed_certificates}.where{signed_certificates.status=="revoked"}
    end

    def unused
      joins(:certificate_contents).where{certificate_contents.workflow_state == 'new'}
    end
  end
  has_many  :validations, through: :certificate_orders
  has_many  :site_seals, through: :certificate_orders
  has_many  :certificate_contents, through: :certificate_orders
  has_many  :domains, :dependent => :destroy
  has_many  :csrs, through: :certificate_contents
  has_many  :managed_csrs
  has_many  :signed_certificates, through: :certificate_contents do
    def expired
      where{expiration_date < Date.today}
    end

    def revoked
      where{status=="revoked"}
    end
  end
  has_many  :certificate_contacts, through: :certificate_contents
  has_many  :registrants, through: :certificate_contents
  has_one   :epki_registrant, -> { where(status: Contact::statuses[:epki_agreement]) },
            as: :contactable, class_name: 'Registrant', dependent: :destroy
  has_one   :reseller, :dependent => :destroy
  has_one   :affiliate, :dependent => :destroy
  has_one   :funded_account, :dependent => :destroy
  has_many  :orders, :as=>:billable, :after_add=>:build_line_items
  has_many  :monthly_invoices, as: :billable
  has_many  :daily_invoices, as: :billable
  has_many  :invoices, as: :billable
  has_many  :transactions, through: :orders
  has_many  :user_groups
  has_many  :api_certificate_requests, as: :api_requestable, dependent: :destroy
  has_many  :api_certificate_create_v1_4s, as: :api_requestable, class_name: "ApiCertificateCreate_v1_4"
  has_many  :api_certificate_retrieves, as: :api_requestable, class_name: "ApiCertificateRetrieve"
  has_many  :account_roles, class_name: "Role" # customizable roles that belong to this account
  has_many  :ssl_account_users, dependent: :destroy
  has_many  :users, -> { unscope(where: [:status]) }, through: :ssl_account_users
  has_many  :unscoped_users, through: :ssl_account_users
  has_many  :assignments
  has_many  :discounts, as: :benefactor, dependent: :destroy
  has_many  :saved_contacts, as: :contactable, class_name: 'CertificateContact', dependent: :destroy
  has_many  :saved_registrants, as: :contactable, class_name: 'Registrant', dependent: :destroy
  has_many  :all_saved_contacts, as: :contactable, class_name: 'Contact', dependent: :destroy
  has_many  :individual_validations, as: :contactable, class_name: 'IndividualValidation', dependent: :destroy
  has_many  :cdns
  has_many  :tags
  has_many  :folders, dependent: :destroy
  has_many  :notification_groups
  has_many  :scan_logs, through: :notification_groups
  has_many  :certificate_names, through: :certificate_contents
  has_many  :domain_control_validations, through: :certificate_names do
    def sslcom
      where.not certificate_contents: {ca_id: nil}
    end
  end
  has_many  :registered_agents
  has_many  :cas_certificates
  has_many  :cas, through: :cas_certificates
  has_many  :certificate_order_tokens
  has_many  :certificate_enrollment_requests

  accepts_nested_attributes_for :reseller, :allow_destroy=>false

  unless MIGRATING_FROM_LEGACY
    #has_many  :orders, :as=>:billable, :after_add=>:build_line_items
    attr_readonly :acct_number
  end

  preference  :reminder_status, :default=>true
  preference  :reminder_notice_triggers, :string
  preference  :reminder_include_reseller, :default=>true
  preference  :reminder_notice_destinations, :string, :default=>"0"
  preference  :reminder_include_cert_admin, :default=>true
  preference  :reminder_include_cert_tech, :default=>true
  preference  :processed_include_reseller, :default=>true
  preference  :processed_certificate_recipients, :string, :default=>"0"
  preference  :processed_include_cert_admin, :string, :default=>true
  preference  :processed_include_cert_tech, :string, :default=>true
  preference  :processed_include_reseller, :default=>true
  preference  :receipt_include_reseller, :default=>true
  preference  :receipt_recipients, :string, :default=>"0"
  preference  :receipt_include_cert_admin, :string, :default=>true
  preference  :receipt_include_cert_bill, :string, :default=>true
  preference  :confirmation_include_reseller, :default=>true
  preference  :confirmation_recipients, :string, :default=>"0"
  preference  :confirmation_include_cert_admin, :string, :default=>true
  preference  :confirmation_include_cert_bill, :string, :default=>true
  preference  :po_capable, default: false

  before_validation :b_create, on: :create
  after_create  :initial_setup
  after_save { users.find_each(&:touch) }

  BILLING_METHODS = ['monthly', 'due_at_checkout', 'daily']
  PULL_RESELLER = "pull_from_reseller"
  PULL_ADMIN_TECH = "pull_from_admin_and_tech"
  PULL_ADMIN = "pull_from_admin"
  HUMAN_ATTRIBUTES = {
    :preferred_processed_certificate_recipients=>"Certificate recipients",
    :preferred_reminder_notice_destinations=>"Reminder recipients",
    :preferred_receipt_recipients=>"Receipt recipients",
    :preferred_confirmation_recipients=>"Confirmation recipients"
      }
  SETTINGS_SECTIONS = %w(processed_certificate receipt confirmation)
  NUMBER_OF_TRIGGERS = 5
  TRIGGER_RANGE = -364..364
  @@reserved_routes ||= Rails.application.routes.named_routes.map{|r| r.to_s}
  SHOW_TEAMS_THRESHOLD=0
  SETTINGS_SECTIONS.each do |item|
    validate "#{item}_recipients_format".to_sym,
      :unless=>"preferred_#{item}_recipients=='0'"
  end
  validate :reminder_notice_destinations_format,
    :unless=>"preferred_reminder_notice_destinations=='0'"
  validate :preferred_reminder_notice_triggers_format
  validates :acct_number, presence: true, uniqueness: true, on: :create
  validates :ssl_slug, uniqueness: {case_sensitive: false}, length: {in: 2..20}, allow_nil: true
  validates :company_name, length: {in: 2..20}, allow_nil: true

  # default_scope ->{order("ssl_accounts.created_at desc")}
  default_scope{where{workflow_state << ['archived']}.order("ssl_accounts.created_at desc")}

  include Workflow
  workflow do
    state :active do
      event :archive, :transitions_to => :archived
    end

    state :archived do
      event :retrieve, :transitions_to => :active
    end
  end

  #before create function
  def b_create
    self.acct_number='a'+SecureRandom.hex(1)+
        '-'+Time.now.to_i.to_s(32)
  end

  # before filter
  def initial_setup
    self.preferred_reminder_notice_triggers = "60", ReminderTrigger.find(1)
    self.preferred_reminder_notice_triggers = "30", ReminderTrigger.find(2)
    self.preferred_reminder_notice_triggers = "7", ReminderTrigger.find(3)
    self.preferred_reminder_notice_triggers = "1", ReminderTrigger.find(4)
    self.preferred_reminder_notice_triggers = "-30", ReminderTrigger.find(5)
    generate_funded_account
    create_api_credential if api_credential.blank?
    create_folders
  end

  def api_credential
    api_credentials.last
  end
  memoize :api_credential

  def create_api_credential
    @ac = ApiCredential.new
    @ac.ssl_account_id = self.id
    @ac.roles = "[#{Role.get_account_admin_id}]"
    @ac.save
  end

  def self.human_attribute_name(attr, options={})
     HUMAN_ATTRIBUTES[attr.to_sym] || super
  end

  def generate_funded_account
    self.funded_account = FundedAccount.new(:cents=>0)
  end

  def total_amount_paid
    Money.new(orders.not_test.inject(0) do
        |sum, o| sum+=o.cents end)
  end

  def total_certs_bought
    certificate_orders.not_new.count
  end

  def self.top_paid(include=[:users, :orders])
    includes(include).sort {|a,b|
      a.total_amount_paid <=> b.total_amount_paid}
  end

  def self.top_paid_users(how_many=10)
    top_paid.last(how_many).map{|s|s.primary_user}

  end

  def self.top_paid_amounts(how_many=10)
    top_paid([:orders]).last(how_many).map(&:total_amount_paid).map(&:format)
  end

  def reseller_tier_label
    reseller.reseller_tier.label if (reseller && reseller.reseller_tier)
  end

  # def signed_certificates
  #   certificate_orders.map(&:certificate_contents).flatten.compact.
  #     map(&:csr).flatten.compact.map(&:signed_certificate)
  # end

  def unique_first_signed_certificates
    ([]).tap do |result|
      tmp_certs={}
      signed_certificates.compact.each do |sc|
        if tmp_certs[sc.common_name]
          tmp_certs[sc.common_name] << sc
        else
          tmp_certs.merge! sc.common_name => [sc]
        end
      end
      tmp_certs
      tmp_certs.each do |k,v|
        result << tmp_certs[k].min{|a,b|a.created_at.to_i <=> b.created_at.to_i}
      end
    end
  end

  # does this domain satisfy pending validations of other domains on this team? Return list of satisfied names
  # domain - the domain that has satisfied DV
  # dcv - the domain control validation method that was satisfied
  def satisfy_related_dcvs(domain)
    dcv = domain.domain_control_validations.last
    [].tap do |satisfied_names|
      all_certificate_names.includes(:domain_control_validations).each do |certificate_name|
        if certificate_name.name!=domain.name and
            DomainControlValidation.domain_in_subdomains?(domain.name,certificate_name.name) and
            # team validated domain
            (domain.certificate_content_id==nil or
            # do they have the same public key
            (domain.csr and certificate_name.csr and
                domain.cached_csr_public_key_sha1==certificate_name.cached_csr_public_key_sha1))
          certificate_name.domain_control_validations.create(dcv.attributes.except("id"))
          certificate_name.certificate_content.certificate_order.apply_for_certificate if certificate_name.certificate_content
          satisfied_names << certificate_name.name
        end
      end
    end
  end

  # is this domain's validation satisfied by an already validated domain. If so, create a dcv with satisfied status
  # certificate_name - the domain we are looking up
  # TODO create all_root_cerificate_names that search for the base root domain of certificate_name; no need to load all domains
  def other_dcvs_satisfy_domain(certificate_name)
    all_certificate_names(certificate_name.name).includes(:domain_control_validations).each do |cn|
      if cn.id!=certificate_name.id and DomainControlValidation.domain_in_subdomains?(cn.name,certificate_name.name)
        dcv = cn.domain_control_validations.last
        if dcv && dcv.identifier_found
          # email validation
          if dcv.dcv_method =~ /email/ or
          # http/s or cname must have the same public key
              (cn.csr and certificate_name.csr and
                  cn.cached_csr_public_key_sha1==certificate_name.cached_csr_public_key_sha1)
            certificate_name.domain_control_validations.create(dcv.attributes.except("id"))
            break
          end
        end
      end
    end
  end

  def unique_signed_certificates
    ([]).tap do |result|
      tmp_certs={}
      signed_certificates.compact.each do |sc|
        if tmp_certs[sc.common_name]
          tmp_certs[sc.common_name] << sc
        else
          tmp_certs.merge! sc.common_name => [sc]
        end
      end
      tmp_certs
      tmp_certs.each do |k,v|
        result << tmp_certs[k].max{|a,b|a.expiration_date.to_i <=> b.expiration_date.to_i}
      end
    end
  end

  def unrenewed_signed_certificates(renew_threshold=nil)
    unique_signed_certificates.select{|sc|
      sc.certificate_order.renewal.blank? || (renew_threshold ?
          (sc.certificate_order.renewal.created_at < renew_threshold.days.ago) : false)}
  end

  def renewed_signed_certificates
    unique_signed_certificates.select{|sc| sc.certificate_order.renewal}
  end

  def can_buy?(item)
    item = Certificate.for_sale.find_by_product(item[ShoppingCart::PRODUCT_CODE]) if item.is_a?(Hash)
    if item.blank?
      return false
    elsif item.reseller_tier.nil?
      return true
    elsif reseller.nil?
      return false
    end
    true if item.reseller_tier == reseller.reseller_tier
  end

  def is_registered_reseller?
    Rails.cache.fetch("#{cache_key}/is_registered_reseller") do
      has_role?('reseller') && reseller.try("complete?")
    end
  end

  def clear_new_certificate_orders
    certificate_orders.is_new.each(&:destroy)
  end

  def clear_new_product_orders
    product_orders.is_new.each(&:destroy)
  end

  def has_only_credits?
    (certificate_orders.credits.count > 0) && (certificate_orders.credits.count==certificate_orders.not_new.count)
  end

  def has_credits?
    certificate_orders.unused_credits.count > 0
  end

  def has_certificate_orders?
    certificate_orders.not_new.count > 0
  end

  # do any default certificates map to SSL.com chained Roots
  def show_domains_manager?
    Rails.cache.fetch("#{cache_key}/show_domains_manager") do
      cas_certificates.default.any?{|cc|cc.certificate.is_server?}
    end or
    Rails.cache.fetch(CasCertificate::GENERAL_DEFAULT_CACHE) do
      CasCertificate.general.default.any?{|cc|cc.certificate.is_server?}
    end
  end

  %W(receipt confirmation).each do |et|
    define_method("#{et}_recipients") do
      [].tap do |addys|
        addys << reseller.email if
          is_registered_reseller? &&
          send("preferred_#{et}_include_reseller?")
        addys << send("preferred_#{et}_recipients") unless
          send("preferred_#{et}_recipients")=="0"
        addys.uniq!
        addys << users.map(&:email); addys.flatten!; addys.uniq! if
          addys.empty?
      end
    end
  end

  def set_reseller_default_prefs
    self.preferred_reminder_include_cert_admin=false
    self.preferred_reminder_include_cert_tech=false
    self.preferred_processed_include_cert_admin=false
    self.preferred_processed_include_cert_tech=false
    self.preferred_receipt_include_cert_admin=false
    self.preferred_receipt_include_cert_bill=false
    self.preferred_confirmation_include_cert_admin=false
    self.preferred_confirmation_include_cert_bill=false
    self.save
  end

  def tier_suffix
    (reseller && reseller.reseller_tier) ? ResellerTier.tier_suffix(reseller.reseller_tier.label) : ""
  end

  #def order_transactions
  #  oids=Order.select("orders.id").joins(:billable.type(SslAccount)).
  #      where(:billable_id=>id).map(&:id)
  #  OrderTransaction.where(:order_id + oids)
  #end
  #
  #def successful_order_transactions
  #  order_transactions.where :success=>true
  #end

  # this upgrades or downgrades the account into a reseller tier
  def adjust_reseller_tier(tier, reseller_fields=Reseller::TEMP_FIELDS)
    #if account is not reseller, do it now else just change the tier number
    if reseller.blank?
      create_reseller(reseller_fields.reverse_merge(reseller_tier_id: ResellerTier.find_by_label(tier).id))
      roles << "reseller"
      set_reseller_default_prefs
      users.each do |u|
        u.set_roles_for_account(self, [Role.find_by_name(Role::RESELLER).id])
      end
    else
      reseller.reseller_tier=ResellerTier.find_by_label(tier)
      reseller.save
    end
    roles << "reseller" unless is_reseller?
    roles.delete "new_reseller" if is_new_reseller?
    save
    reseller.completed! unless reseller.complete?
  end

  def api_certificate_requests_string
    acr=api_certificate_requests.last
    if acr
      'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X PUT -d '+
          acr.raw_request.to_json + " " +acr.request_url
    end
  end

  def adjust_funds(cents)
    funded_account.update_attribute :cents, funded_account.cents+=cents
  end

  def self.api_credentials_for_all
    self.find_each{|s|s.create_api_credential if s.api_credential.blank?}
  end

  def self.migrate_deposit(from_sa, to_sa, deposit, user)
    to_sa.orders << deposit if deposit
    if deposit && to_sa.orders.include?(deposit)
      SystemAudit.create(
        owner: user,
        target: deposit,
        notes: "Transfered deposit #{deposit.reference_number} from team acct ##{from_sa.acct_number} to team acct ##{to_sa.acct_number} on #{DateTime.now.strftime('%c')}.",
        action: "Transfer Deposit To Team"
      )
    end
  end

  # from_sa - the ssl_account to migrate from
  # to_sa - the ssl_account to migrate to
  def self.migrate_orders(from_sa, to_sa, refs=[], user)
    unless refs.blank?
      orders_list = []
      co_list = []
      Order.where(reference_number: refs).each do |o|
        to_sa.certificate_orders << o.cached_certificate_orders
        o.cached_certificate_orders.each do |co|
          co_orders = co.orders
          to_sa.orders << co_orders
          orders_list << co_orders
          co_list << co
        end
      end
      orders_list = orders_list.flatten.uniq.compact
      co_list = co_list.flatten.uniq.compact
      params = {
        from_sa: from_sa,
        to_sa: to_sa,
        orders_list: orders_list,
        co_list: co_list,
        user: user
      }
      if orders_list.any?
        OrderNotifier.order_transferred(params).deliver_now
        migrate_orders_to_invoices(to_sa, orders_list)
        migrate_orders_associations(params)
      end
      co_list.map(&:certificate_contacts).flatten.uniq.compact.each do |contact|
        contact.update(parent_id: nil)
      end
      migrate_orders_system_audit(params)
    end
  end

  def self.migrate_orders_associations(params)
    list = []
    # Funded Account Withdrawal used to pay for order
    params[:orders_list].each do |o|
      list << Order.where('description LIKE ?', "%#{Order::FAW}%")
        .where('notes LIKE ?', "%#{o.reference_number}%").first
    end
    # Deposits used to pay for order
    list << Order.where(id: params[:orders_list].map(&:deducted_from_id))
    list = list.flatten.compact.uniq
    params[:to_sa].orders << list if list.any?
  end

  def self.migrate_orders_system_audit(params)
    notes_ext = "from team acct ##{params[:from_sa].acct_number} to team acct ##{params[:to_sa].acct_number} on #{DateTime.now.strftime('%c')}"

    params[:co_list].each do |co|
      SystemAudit.create(
        owner: params[:user],
        target: co,
        notes: "Transfered certificate order #{co.ref} #{notes_ext}.",
        action: "Transfer Certificate Order To Team"
      )
    end
    params[:orders_list].each do |o|
      SystemAudit.create(
        owner: params[:user],
        target: o,
        notes: "Transfered order #{o.reference_number} #{notes_ext}.",
        action: "Transfer Order To Team"
      )
    end
  end

  def self.migrate_orders_to_invoices(to_sa, orders_list=[])
    invoiced_orders = orders_list.select {|io| io.state == 'invoiced'}
    pending_invoice = nil
    invoiced_orders.each do |o|
      from_invoice = o.invoice
      if from_invoice
        exclude_params = %w{id reference_number created_at updated_at billable_id}
        cur_params = from_invoice.attributes.except!(*exclude_params)
          .merge(billable_id: to_sa.id)
        target_invoice = if from_invoice.pending? && pending_invoice.nil?
          pending_invoice = Invoice.get_or_create_for_team(to_sa)
        else
          Invoice.create(cur_params)
        end
        o.update(invoice_id: target_invoice.try(:id)) if target_invoice
      end
      from_invoice.destroy if from_invoice.orders.empty?
    end
  end

  def primary_user
    users.first
  end

  def self.ssl_slug_valid?(slug_str)
    cur_ssl_slug = slug_str.strip.downcase
    !cur_ssl_slug.blank? &&
      SslAccount.find_by(ssl_slug: cur_ssl_slug).nil? &&
      !@@reserved_routes.include?(cur_ssl_slug) &&
      cur_ssl_slug.gsub(/([a-zA-Z]|_|-|\s|\d)/, '').length == 0
  end

  def get_invoice_label
    return 'monthly' if billing_monthly?
    return 'daily' if billing_daily?
    ''
  end

  def domain_names(only_ca = true)
    cnames = self.certificate_names.order(created_at: :desc)
    dnames = self.domains.order(created_at: :desc)
    domain_names = []
    cnames.each do |cn|
      unless only_ca
        domain_names << cn.name unless domain_names.include?(cn.name)
      else
        domain_names << cn.name unless domain_names.include?(cn.name) && cn.certificate_content.ca_id.nil?
      end
    end
    dnames.each do |dn|
      domain_names << dn.name unless domain_names.include?(dn.name)
    end
    domain_names
  end

  # concatenate team (Domain) and order scoped certificate_names
  def all_certificate_names(root=nil,scope="sslcom")
    if root
      d=::PublicSuffix.parse(root)
      CertificateName.where(id: (Rails.cache.fetch("#{cache_key}/all_certificate_names/#{scope}/#{d.domain}") {
        name_sql=->(scoped_names){scoped_names.where('name like ? OR name = ?', '%.'+d.domain ,d.domain)}
        (name_sql.call(scope=="sslcom" ? self.certificate_names.sslcom : self.certificate_names)+
            name_sql.call(self.domains)).map(&:id).uniq
      })).order(updated_at: :desc)
    else
      CertificateName.where(id: (Rails.cache.fetch("#{cache_key}/all_certificate_names/#{scope}") {
        ((scope=="sslcom" ? self.certificate_names.sslcom : self.certificate_names)+self.domains).map(&:id).uniq
      })).order(updated_at: :desc)
    end
  end
  memoize :all_certificate_names

  def all_csrs
    Csr.where(id: (Rails.cache.fetch("#{cache_key}/all_csrs") {
      if managed_csrs.empty?
        csrs
      elsif csrs.empty?
        managed_csrs
      else
        (csrs + managed_csrs)
      end.reject{|csr|csr.public_key_sha1.blank?}.uniq(&:public_key_sha1).map(&:id)
    })).order(created_at: :desc)
  end

  def validated_domains
    validated_domains = []
    cnames = self.certificate_names
    cnames.each do |cn|
      dcv = cn.domain_control_validations.last
      if dcv && dcv.identifier_found
        validated_domains << cn.name unless validated_domains.include?(cn.name)
      end
    end
    validated_domains
  end

  def is_validated?(domain)
    validated_domains.include?(domain)
  end

  def get_invoice_pmt_description
    billing_monthly? ? Order::MI_PAYMENT : Order::DI_PAYMENT
  end

  def get_account_admins
    uid=Rails.cache.fetch("#{cache_key}/get_account_admins") do
      users.with_role(Role::ACCOUNT_ADMIN).pluck(:user_id).uniq
    end
    uid ? User.find(uid) : nil
  end
  memoize :get_account_admins

  def get_account_owner
    uid=Rails.cache.fetch("#{cache_key}/get_account_owner") do
      Assignment.where(
        role_id: [Role.get_owner_id, Role.get_reseller_id], ssl_account_id: id
      ).pluck(:user_id).first
    end
    uid ? User.find(uid) : nil
  end
  memoize :get_account_owner

  # def get_account_admins
  #   uid=Rails.cache.fetch("#{cache_key}/get_account_admins") do
  #     Assignment.where(
  #       role_id: [Role.get_account_admin_id], ssl_account_id: id
  #     ).pluck(:user_id)
  #   end
  #   uid ? User.find(uid) : nil
  # end
  # memoize :get_account_admins
  #
  def cached_users
    User.where(id: (Rails.cache.fetch("#{cache_key}/cached_users") do
      users.pluck(:id).uniq
    end))
  end

  def cached_certificate_names
    CertificateName.where(id: (Rails.cache.fetch("#{cache_key}/cached_certificate_names") do
      certificate_names.pluck(:id).uniq
    end))
  end

  def cached_orders
    Order.where(id: (Rails.cache.fetch("#{cache_key}/cached_orders") do
      orders.pluck(:id).uniq
    end)).order(created_at: :desc)
  end
  memoize :cached_orders

  def cached_certificate_orders
    CertificateOrder.where(id: (Rails.cache.fetch("#{cache_key}/cached_certificate_orders") do
      certificate_orders.pluck(:id).uniq
    end)).order(created_at: :desc)
  end
  memoize :cached_certificate_orders

  def cached_certificate_orders_count
    Rails.cache.fetch("#{cache_key}/cached_certificate_orders_count") do
      cached_certificate_orders.count
    end
  end
  memoize :cached_certificate_orders_count

  def cached_certificate_orders_pending
    CertificateOrder.where(id: (Rails.cache.fetch("#{cache_key}/cached_certificate_orders_pending") do
      certificate_orders.pending.pluck(:id)
    end)).order(created_at: :desc)
  end
  memoize :cached_certificate_orders_pending

  def cached_certificate_orders_incomplete
    CertificateOrder.where(id: (Rails.cache.fetch("#{cache_key}/cached_certificate_orders_incomplete") do
      certificate_orders.incomplete.pluck(:id)
    end)).order(created_at: :desc)
  end
  memoize :cached_certificate_orders_incomplete

  def cached_certificate_orders_credits
    CertificateOrder.where(id: (Rails.cache.fetch("#{cache_key}/cached_certificate_orders_credits") do
      certificate_orders.credits.pluck(:id)
    end)).order(created_at: :desc)
  end
  memoize :cached_certificate_orders_credits

  def cached_certificate_orders_credits_count
    Rails.cache.fetch("#{cache_key}/cached_certificate_orders_credits_count") do
      cached_certificate_orders_credits.count
    end
  end
  memoize :cached_certificate_orders_credits_count

  def cached_certificate_orders_pending_count
    Rails.cache.fetch("#{cache_key}/cached_certificate_orders_pending_count") do
      cached_certificate_orders_pending.count
    end
  end
  memoize :cached_certificate_orders_pending_count

  def cached_certificate_orders_incomplete_count
    Rails.cache.fetch("#{cache_key}/cached_certificate_orders_incomplete_count") do
      cached_certificate_orders_incomplete.count
    end
  end
  memoize :cached_certificate_orders_incomplete_count

  def get_team_name
    company_name || acct_number
  end

  def to_slug
    ssl_slug || acct_number
  end

  def expiring_certificates_for_old
    results=[]

    unique_first_signed_certificates.compact.each do |sc|
      pd = (sc.expiration_date - sc.effective_date) / 1.day
      ecd = sc.csr.certificate_content.duration

      if pd && ecd
        if (ecd - pd) > 825
          results << Struct::Reminding.new(2, sc)
        elsif (ecd - pd) > 365
          results << Struct::Reminding.new(1, sc)
        end
      end
    end

    results

    # unrenewed_signed_certificates.compact.each do |sc|
    #   scd = sc.created_at
    #   sed = sc.expiration_date
    #   unless sed.blank?
    #     if (((scd + 3.years) < sed) &&
    #         (Time.now < sed) &&
    #         (scd > 3.years.from_now) &&
    #         (scd < (Time.now - 2.years - 10.months)))
    #       results << Struct::Expiring.new(sc)
    #     end
    #   end
    # end
  end

  def expiring_certificates
    results=[]

    if preferred_reminder_status
      exp_dates=ReminderTrigger.all.map do|rt|
        preferred_reminder_notice_triggers(rt).to_i
      end.sort{|a,b|b<=>a} # order from highest to lowest value

      unrenewed_signed_certificates.compact.each do |sc|
        sed = sc.expiration_date
        unless sed.blank?
          exp_dates.each_with_index do |ed, i|
            # determine if valid to send reminders and/or rebill at this point
            if (i < exp_dates.count-1 && # be sure we don't over iterate
                sed < ed.to_i.days.from_now && # is signed certificate expiration between exp intervals?
                sed >= exp_dates[i+1].days.from_now)
              results << Struct::Expiring.new(ed,exp_dates[i+1],sc) unless
                  renewed?(sc, exp_dates.first.to_i)
              break
            end
          end
        end
      end
    end

    results
  end

  # years back - how many years back do we want to go on expired certificates
  def expired_certificates(intervals, years_back=1)
    year_in_days = 365
    (Array.new(intervals.count){|i|i=[]}).tap do |results|
      if preferred_reminder_status
        unrenewed_signed_certificates.compact.each do |sc|
          sed = sc.expiration_date
          unless sed.blank?
            years_back.times do |i|
              years = year_in_days * (i+1)
              adj_int = intervals.map{|i|i+years}
              adj_int.each_with_index do |ed, i|
                if i < adj_int.count-1 &&
                    sed < ed.to_i.days.ago &&
                    sed >= adj_int[i+1].days.ago
                  results[i] << Struct::Expiring.new(ed,adj_int[i+1],sc) unless
                      renewed?(sc, intervals.last)
                  break
                end
              end
            end
          end
        end
      end
    end
  end

  #Reminder.preparing_recipients to locate point of injection for do-not-send list
  def self.send_reminders
    # ActiveRecord::Base.logger.level = Logger::INFO
    logger.info "Sending SSL.com cert reminders. Type 'Q' and press Enter to exit this program"
    SslAccount.unscoped.order('created_at').includes(
        [:stored_preferences, {:certificate_orders =>
                                   [:orders]}]).find_in_batches(batch_size: 250) do |s|
      # find expired certs based on triggers.
      logger.info "filtering out expired certs"
      e_certs=s.map{|s|s.expiring_certificates}.reject{|e|e.empty?}.flatten
      digest={}
      self.send_and_create_reminders(e_certs, digest)
      #find expired certs from n*1 years ago from ssl_accounts that do not have
      #recent purchase history
      remove = e_certs.map(&:cert).flatten.map(&:ssl_account).uniq
      # should also filter out ssl_accounts who have recently logged in. We don't
      # want to constantly email them even if they have expired certs from a several
      # years ago
      s = s - remove
      digest.clear
      intervals = [-30, -7, 16, 31] #0 represents this day, n * 1 years ago
      e_certs = s.map{|s|s.expired_certificates(intervals)}.
          transpose.map{|ec|ec.reject{|e|e==[]}.flatten}.flatten.compact
      self.send_and_create_reminders(e_certs, digest, true, intervals)
    end
    logger.info "exiting ssl reminder app"
  end

  # def self.test
  #   SslAccount.unscoped.order('created_at').includes(
  #       [:stored_preferences, {:certificate_orders =>
  #                                  [:orders, :certificate_contents=>
  #                                      {:csr=>:signed_certificates}]}]).find_in_batches(batch_size: 250) do |batch_list|
  #     logger.info "Filtering out expiring certs"
  #     e_certs = batch_list.map{|batch| batch.expiring_certificates_for_old}.reject{|e|e.empty?}.flatten
  #     digest = {}
  #     SslAccount.send_notify(e_certs, digest)
  #   end
  # end

  def self.send_notify(expiring_certs, digest)
    expiring_certs.each do |ec|
      cert = ec.cert
      contacts=[cert.csr.certificate_content.technical_contact,cert.csr.certificate_content.administrative_contact]
      contacts.uniq.compact.each do |contact|
        logger.info "adding contact to digest"
        unless contact.email.blank? ||
            SentReminder.exists?(trigger_value: ec.year,
                                 expires_at: cert.expiration_date,
                                 subject: cert.common_name,
                                 recipients: contact.email)
          dk = contact.to_digest_key
          if digest[dk].blank?
            digest.merge!({dk => [ec]})
          else
            digest[dk] << ec
          end
        end
      end
    end
    unless digest.empty?
      digest.each do |d|
        u_certs = d[1].map(&:cert).map(&:common_name).uniq.compact
        begin
          unless u_certs.empty?
            logger.info "Sending notification"
            body = Reminder.digest_notify(d)
            body.deliver unless body.to.empty?
          end
          d[1].each do |ec|
            logger.info "create SentReminder"
            SentReminder.find_or_initialize_by(trigger_value: ec.year,
                                expires_at: ec.cert.expiration_date,
                                signed_certificate_id: ec.cert.id,
                                subject: ec.cert.common_name,
                                body: body,
                                recipients: d[0].split(",").last).save
          end
        rescue Exception=>e
          logger.error e.backtrace.inspect
          raise e
        end
      end
    end
  end

  def self.send_and_create_reminders(expired_certs, digest, past=false,
      interval=nil)
    expired_certs.each do |ec|
      exempt_list = %w(
          hepsi danskhosting webcruit
          epsa\.com\.co
          magicexterminating suburbanexterminating)
      exempt_certs = ->(domain, exempt){exempt.find do |e|
        domain=~eval("/#{e}/")
      end}
      if true #this should be a function testing for message digest
        detect_abort
        c = ec.cert
        contacts=[c.csr.certificate_content.technical_contact,
                  c.csr.certificate_content.administrative_contact]
        contacts.uniq.compact.each do |contact|
          logger.info "adding contact to digest"
          unless contact.email.blank? ||
              SentReminder.exists?(trigger_value:
                  [ec.before, ec.after].join(", "),
              expires_at: c.expiration_date, subject: c.common_name,
              recipients: contact.email) ||
              exempt_certs.(c.common_name, exempt_list)
            dk=contact.to_digest_key
            if digest[dk].blank?
              digest.merge!({dk => [ec]})
            else
              digest[dk] << ec
            end
          end
        end
      else #currently doesn't get used
        unless ec.cert.expiration_date.blank?
          ec.cert.send_expiration_reminder(ec)
        else
          logger.error "blank expiration date for #{ec.cert.common_name}"
        end
      end
    end
    unless digest.empty?
      digest.each do |d|
        detect_abort
        u_certs = d[1].map(&:cert).map(&:common_name).uniq.compact
        begin
          unless u_certs.empty?
            logger.info "Sending reminder"
            body = past ? Reminder.past_expired_digest_notice(d, interval) :
                       Reminder.digest_notice(d)
            begin
              body.deliver unless body.to.empty?
            rescue Exception=>e
              logger.error e.backtrace.inspect
            end
          end
          d[1].each do |ec|
            logger.info "create SentReminder"
            SentReminder.create(trigger_value: [ec.before, ec.after].join(", "),
                                expires_at: ec.cert.expiration_date, signed_certificate_id:
                                    ec.cert.id, subject: ec.cert.common_name,
                                body: body, recipients: d[0].split(",").last)
          end
        rescue Exception=>e
          logger.error e.backtrace.inspect
          raise e
        end
      end
    end
  end

  def billing_monthly?
    billing_method == 'monthly' || no_limit
  end

  def billing_daily?
    billing_method == 'daily'
  end

  def invoice_required?
    billing_monthly? || billing_daily? || no_limit
  end

  protected

  def create_folders
    archive_folder = Folder.find_or_create_by(
        name: 'archived', archived: true, ssl_account_id: self.id
    )

    default_folder = Folder.find_by(
        default: true, ssl_account_id: self.id
    ) || Folder.create(name: 'default', default: true, ssl_account_id: self.id)

    expired_folder = Folder.find_or_create_by(
        name: 'expired', expired: true, ssl_account_id: self.id
    )

    active_folder = Folder.find_or_create_by(
        name: 'active', active: true, ssl_account_id: self.id
    )

    revoked_folder = Folder.find_or_create_by(
        name: 'revoked', revoked: true, ssl_account_id: self.id
    )

    self.update_column(:default_folder_id, default_folder.id)
  end

  private

  # creates dev db from production. NOTE: This will modify the db data so use this on a COPY of the production db
  # SslAccount.convert_db_to_development
  def self.convert_db_to_development(ranges=[["08/01/2016","09/01/2016"],["08/01/2017","09/01/2017"]],size=1000)
    require "declarative_authorization/maintenance"
    SentReminder.unscoped.delete_all
    TrackedUrl.unscoped.delete_all
    Tracking.unscoped.delete_all
    VisitorToken.unscoped.delete_all
    CaApiRequest.unscoped.delete_all
    unless ranges.blank?
      ranges.each do |range|
        start,finish=range[0], range[1]
        if start.is_a?(String)
          s= start =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
          f= finish =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
          range[0] = Date.strptime start, s
          range[1] = Date.strptime finish, f
        end
      end
      %w(User SslAccount SiteSeal BillingProfile CertificateOrder Order DomainControlValidation
        CertificateContent CertificateName Csr SignedCertificate Contact Validation ValidationHistory ValidationHistoryValidation
        ValidationRulingValidationHistory Assignment Preference ShoppingCart SiteCheck Permission SystemAudit
        ApiCredential CaApiRequest Reseller).each {|table|
          sql = (['created_at BETWEEN ? AND ?']*ranges.count).join(" OR ")
          table.constantize.unscoped.where.not(sql, *(ranges.flatten)).delete_all
      }
    end
    ActiveRecord::Base.connection.tables.map do |model|
      unless %w(auto_renewals delayed_job).include?(model)
        begin
          klass = model.capitalize.singularize.camelize.constantize
          klass.where{created_at > from.days.ago}.delete_all
        rescue

        end
      end
    end
    # Obfuscate IDs
    i=100000
    ApiCredential.unscoped.find_each(batch_size: size){|a|
      a.update_columns account_key: i, secret_key: i
      i+=1}
    i=10000
    SiteSeal.unscoped.find_each(batch_size: size){|s|
      s.update_column :ref,i
      i+=1}
    # Obfuscate IDs
    i=10000
    SslAccount.class_eval do
      def self.readonly_attributes
        []
      end
    end
    SslAccount.unscoped.find_each(batch_size: size){|s|
      s.acct_number=i
      s.save validate: false
      i+=1}
    i=10000
    # scramble usernames, emails
    User.unscoped.find_each(batch_size: size) {|u|
      u.update_columns(login: i, email: "test@#{i.to_s}.com")
      u.password = "123456AsDF#"
      u.save
      i+=1
    }
    i=10000
    CertificateOrder.unscoped.find_each(batch_size: size){|co|
      co.ref = "co-"+i.to_s
      co.external_order_number = "000000"
      co.save
      i+=1
    }
    i=10000
    SignedCertificate.unscoped.find_each(batch_size: size){|sc|
      sc.update_column :organization, (i+=1).to_s
    }
    i=10000
    Csr.unscoped.find_each(batch_size: size){|c|
      c.organization = i.to_s
      c.organization_unit = i.to_s
      c.state = i.to_s
      c.locality = i.to_s
      c.save
      i+=1
    }
    i=10000
    Order.unscoped.find_each(batch_size: size){|o|
      o.update_column :reference_number, (i+=1).to_s
    }
    # obfuscate credit card numbers
    BillingProfile.unscoped.find_each(batch_size: size){|bp|
      bp.card_number="4222222222222"
      bp.first_name = "Bob"
      bp.last_name = "Spongepants"
      bp.address_1 = "123 Houston St"
      bp.address_2 = "Ste 100"
      bp.company = "Company Inc"
      bp.phone = "123456789"
      bp.save}
    # delete visitor tracking IDs,
    # scramble user and contact e-mail addresses,
    [Contact, Reseller].each { |klass| klass.unscoped.find_each(batch_size: size){|c|
      c.first_name = "Bob"
      c.last_name = "Spongepants#{c.id}"
      c.email = "bob@spongepants#{c.id}.com"
      c.company_name="Widgets#{c.id} Inc" if klass.method_defined? :company_name
      c.company="Widgets#{c.id} Inc" if klass.method_defined? :company
      c.organization="Widgets#{c.id} Inc" if klass.method_defined? :organization
      c.website="www.widge#{c.id}.com" if klass.method_defined? :website
      c.address1 = "123 Houston St"
      c.address2 = "Ste #{c.id}"
      c.phone = "#{c.id}"
      c.fax = "#{c.id}"
      c.save validate: false}}
    CertificateOrder.unscoped.where{ssl_account_id==nil}.delete_all
    has_sa = CertificateOrder.unscoped.joins{ssl_account}.pluck :id
    all = CertificateOrder.unscoped.pluck :id
    no_sa = all - has_sa
    CertificateOrder.unscoped.where{id >> no_sa}.delete_all
    # CertificateOrder.unscoped.select{|co|co.certificate_content.issued? && !co.certificate_content.expired? &&
    #     (co.certificate_content.csr.blank? || co.certificate_content.csr.signed_certificate.blank?)}.map(&:destroy)
  end

  SETTINGS_SECTIONS.each do |item|
    define_method("#{item}_recipients_format") do
      emails=[]
      emails = eval("preferred_#{item}_recipients.split(' ')") unless
        eval("preferred_#{item}_recipients.blank?")
      errors.add("preferred_#{item}_recipients".to_sym,
        'cannot be blank') if emails.empty?
      results = emails.reject do |email|
        email =~ /\A([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})\z/
      end
      errors.add("preferred_#{item}_recipients".to_sym,
        'has invalid email addresses') unless (results.empty?)
    end
  end

  def reminder_notice_destinations_format
    emails = []
    emails = preferred_reminder_notice_destinations.split(" ") unless
      preferred_reminder_notice_destinations.blank?
    errors.add(:preferred_reminder_notice_destinations,
      'cannot be blank') if emails.empty?
    results = emails.reject do |email|
      email =~ /\A([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})\z/
    end
    errors.add(:preferred_reminder_notice_destinations,
      'has invalid email addresses') unless (results.empty?)
  end

  def preferred_reminder_notice_triggers_format
    NUMBER_OF_TRIGGERS.times do |i|
      days = preferred_reminder_notice_triggers(ReminderTrigger.find(i+1))
      unless days.blank?
        (errors.add("reminder_notice_trigger #{(i+1).to_s}",
        "must be an integer") unless !!(days=~/\d+/))
        errors.add("reminder_notice_trigger #{(i+1).to_s}",
        "must be in the range "+TRIGGER_RANGE.to_friendly) unless TRIGGER_RANGE.include?(days.to_i)
      end
    end
  end

  def renewed?(sc, renew_date)
    eds=SignedCertificate.where(:common_name=>sc.common_name).
        map(&:expiration_date).compact.sort
    eds.detect do |ed|
      ed > renew_date.days.from_now
    end
  end

  def build_line_items(order)
    #only do for prepaid, because 1-off certificate_orders when added are not
    #necessarily paid for already
    if !order.new_record? && order.line_items.all? {|c|c.sellable.try("is_prepaid?".to_sym) if c.sellable.respond_to?("is_prepaid?".to_sym)}
      begin
        OrderNotifier.certificate_order_prepaid(self, order).deliver
      rescue Exception=>e
        logger.error e.backtrace.inspect
      end
      order.line_items.each do |cert|
        self.certificate_orders << cert.sellable
        cert.sellable.pay!(true) unless cert.sellable.paid?
        cc=cert.sellable.certificate_content
        cc.save unless cc.ca.blank?
      end
    end
  end

  def self.remove_orphans
    ids=User.pluck :ssl_account_id
    SslAccount.where{id << ids}.delete_all
    Preference.where{(owner_type=="SslAccount") & (owner_id << ids)}.delete_all
  end

  def self.quit?
    q_pressed="Q pressed"
    begin
      #See if a 'Q' has been typed yet
      while c = STDIN.read_nonblock(1)
        logger.info q_pressed
        puts q_pressed
        return true if c == 'Q'
      end
      #No 'Q' found
      false
    rescue Errno::EINTR
      false
    rescue Errno::EAGAIN
      # nothing was ready to be read
      false
    rescue EOFError
      # quit on the end of the input stream
      # (user hit CTRL-D)
      true
    end
  end

  #disable for deploying to cron
  def self.detect_abort
    #abort('Exit: user terminated') if Rails.env=~/production/i && quit?
  end
end
