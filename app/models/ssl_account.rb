class SslAccount < ActiveRecord::Base
  using_access_control
  acts_as_billable
  easy_roles :roles
  has_one   :api_credential
  has_many  :users_unscoped, foreign_key: :ssl_account_id, class_name: "UserUnscoped", :dependent=>:destroy
  has_many  :billing_profiles
  has_many  :certificate_orders, -> { unscope(where: [:workflow_state, :is_expired]).includes([:orders]) } do
    def current
      first(:conditions=>{:workflow_state=>['new']})
    end
  end
  has_many  :certificate_contents, through: :certificate_orders
  has_many  :certificate_contacts, through: :certificate_contents
  has_one   :reseller, :dependent => :destroy
  accepts_nested_attributes_for :reseller, :allow_destroy=>false
  has_one   :affiliate, :dependent => :destroy
  has_one   :contact, :as => :contactable
  has_one   :funded_account, :dependent => :destroy
  has_many  :orders, :as=>:billable, :after_add=>:build_line_items
  has_many  :transactions, through: :orders
  has_many  :user_groups
  has_many  :api_certificate_requests, as: :api_requestable, dependent: :destroy
  has_many  :api_certificate_create_v1_4s, as: :api_requestable, class_name: "ApiCertificateCreate_v1_4"
  has_many  :api_certificate_retrieves, as: :api_requestable, class_name: "ApiCertificateRetrieve"
  has_many  :account_roles, class_name: "Role" # customizable roles that belong to this account
  has_many  :ssl_account_users, dependent: :destroy
  has_many  :users, through: :ssl_account_users

  unless MIGRATING_FROM_LEGACY
    #has_many  :orders, :as=>:billable, :after_add=>:build_line_items
    attr_readonly :acct_number
  end

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

  default_scope ->{order("created_at desc")}

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
  end

  def self.human_attribute_name(attr, options={})
     HUMAN_ATTRIBUTES[attr.to_sym] || super
  end

  def generate_funded_account
    self.funded_account = FundedAccount.new(:cents=>0)
  end

  def total_amount_paid
    Money.new(orders.select{|op|op.current_state==:paid}.inject(0) do
        |sum, o| sum+=o.cents end)
  end

  def total_certs_bought
    certificate_orders.not_new.count
  end

  def self.top_paid(include=[:users, :orders])
    all(:include=>include).sort {|a,b|
      a.total_amount_paid <=> b.total_amount_paid}
  end

  def self.top_paid_users(how_many=10)
    top_paid.last(how_many).map{|s|s.primary_user}

  end

  def self.top_paid_amounts(how_many=10)
    top_paid([:orders]).last(how_many).map(&:total_amount_paid).map(&:format)
  end

  def reseller_tier_label
    reseller.reseller_tier.label if has_role?('reseller')
  end

  def signed_certificates
    certificate_orders.map(&:certificate_contents).flatten.compact.
      map(&:csr).flatten.compact.map(&:signed_certificate)
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
        result << tmp_certs[k].max{|a,b|a.expiration_date <=> b.expiration_date}
      end
    end
  end

  def unrenewed_signed_certificates(renew_threshold=nil)
    unique_signed_certificates.select{|sc|
      sc.certificate_order.renewal.blank? || renew_threshold ? (sc.certificate_order.renewal.created_at < renew_threshold.days.ago) : false}
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
    has_role?('reseller') && !reseller.new?
  end

  def clear_new_certificate_orders
    certificate_orders.find_all(&:new?).each(&:destroy)
  end

  def clear_new_product_orders
    product_orders.find_all(&:new?).each(&:destroy)
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

  def reseller_suffix
    (reseller && reseller.reseller_tier) ? reseller.reseller_tier.label+"tr" : ""
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
      create_reseller(reseller_fields.reverse_merge(reseller_tier_id: ResellerTier.find(tier).id))
      roles << "reseller"
      set_reseller_default_prefs
      users.each do |u|
        u.set_roles_for_account(self, [Role.find_by_name(Role::RESELLER).id])
      end
      reseller.update_attribute :workflow_state, "complete"
    else
      reseller.reseller_tier=ResellerTier.find(tier)
      reseller.save
    end
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

  # from_sa - the ssl_account to migrate from
  # to_sa - the ssl_account to migrate to
  def self.migrate_orders(from_sa, to_sa)
    to_sa.orders << from_sa.orders
    to_sa.certificate_orders << from_sa.certificate_orders
  end

  def primary_user
    User.unscoped{users.first}
  end

  def self.ssl_slug_valid?(slug_str)
    !slug_str.blank? &&
      !blacklist_keyword?(slug_str.downcase) &&
      slug_str.strip.gsub(/([a-zA-Z]|_|-|\s|\d)/, '').length == 0
  end

  def get_account_owner
    Assignment.where(
      role_id: Role.get_role_id(Role::ACCOUNT_ADMIN), ssl_account_id: id
    ).map(&:user).first
  end

  def get_team_name
    company_name || acct_number
  end

  def to_slug
    ssl_slug || acct_number
  end

  def self.blacklist_keyword?(str)
    reserved_routes_names.each{|s| return true if str.include?(s)}
    return false
  end

  private

  # creates dev db from production. NOTE: This will modify the db data so use this on a COPY of the production db
  def self.make_dev_db(from=nil)
    SentReminder.delete_all
    TrackedUrl.delete_all
    Tracking.delete_all
    VisitorToken.delete_all
    CaApiRequest.delete_all
    # ActiveRecord::Base.connection.tables.map do |model|
    #   unless %w(auto_renewals delayed_job).include?(model)
    #     begin
    #       klass = model.capitalize.singularize.camelize.constantize
    #       klass.where{created_at > from.days.ago}.delete_all
    #     rescue
    #
    #     end
    #   end
    # end
    # Obfuscate IDs
    i=100000
    ApiCredential.find_each{|a|
      a.account_key=i
      a.secret_key=i
      a.save
      i+=1}
    i=10000
    SiteSeal.find_each{|s|
      s.ref=i
      s.save
      i+=1}
    # Obfuscate IDs
    i=10000
    SslAccount.find_each{|s|
      s.acct_number=i
      s.save
      i+=1}
    i=10000
    # scramble usernames, emails
    User.find_each {|u|
      User.change_login u.login, i
      u.email = "test@#{i.to_s}.com"
      u.password = i.to_s
      u.save
      i+=1
    }
    i=10000
    CertificateOrder.find_each{|co|
      co.ref = "co-"+i.to_s
      co.external_order_number = "000000"
      co.save
      i+=1
    }
    i=10000
    SignedCertificate.find_each{|sc|
      sc.update_column :organization, (i+=1).to_s
    }
    i=10000
    Csr.find_each{|c|
      c.organization = i.to_s
      c.organization_unit = i.to_s
      c.state = i.to_s
      c.locality = i.to_s
      c.save
      i+=1
    }
    i=10000
    Order.find_each{|o|
      o.update_column :reference_number, (i+=1).to_s
    }
    # obfuscate credit card numbers
    BillingProfile.find_each{|bp|
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
    [Contact, Reseller].each { |klass| klass.find_each{|c|
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

  def build_line_items(order)
    #only do for prepaid, because 1-off certificate_orders when added are not
    #necessarily paid for already
    if !order.new_record? && order.line_items.all? {|c|c.sellable.try("is_prepaid?".to_sym) if c.sellable.respond_to?("is_prepaid?".to_sym)}
      OrderNotifier.certificate_order_prepaid(self, order).deliver
      order.line_items.each do |cert|
        self.certificate_orders << cert.sellable
        cert.sellable.pay!(true) unless cert.sellable.paid?
      end
    end
  end

  def self.remove_orphans
    ids=User.pluck :ssl_account_id
    SslAccount.where{id << ids}.delete_all
    Preference.where{(owner_type=="SslAccount") & (owner_id << ids)}.delete_all
  end

  def self.reserved_routes_names
    Rails.application.routes.named_routes.map{|r| r.to_s}
  end
end
