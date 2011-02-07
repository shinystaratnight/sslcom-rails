class SslAccount < ActiveRecord::Base
  using_access_control
  acts_as_billable
  easy_roles :roles
  has_many  :users, :dependent=>:destroy
  has_many  :billing_profiles
  has_many  :certificate_orders, :include => [:orders, :certificate_contents] do
    def unvalidated(options={})
      all(options).find_all{|co|
        next false unless co.certificate_content
        ['pending_validation', 'contacts_provided'].
        include?(co.certificate_content.workflow_state) &&
        !co.validation_rules_satisfied? && !co.expired?}
    end

    def incomplete(options={})
      all(options).find_all{|co|
        next false unless co.certificate_content
        ['csr_submitted', 'info_provided', 'contacts_provided'].
        include?(co.certificate_content.workflow_state) &&
        !co.validation_rules_satisfied? && !co.expired?}
    end

    def pending(options={})
      all(options).find_all{|co|
        next false unless co.certificate_content
        ['pending_validation'].
        include?(co.certificate_content.workflow_state) &&
        !co.validation_rules_satisfied?}
    end

    #new certificate orders are the ones still in the shopping cart
    def not_new(options={})
      if options && options.has_key?(:page)
        self.where("workflow_state = ?",'paid').paginate(options)
      else
        self.all(options || {}).find_all{|co|co.paid?}
      end
    end

    def has_csr(options={})
      all(options).find_all{|co|
        ['paid'].include?(co.workflow_state) &&
        !co.certificate_content.signing_request.blank?}
    end

    def credits(options={})
      all(options).find_all{|co|
        ['paid'].include?(co.workflow_state) &&
          co.certificate_content.try(:new?)}
    end

    def unused_credits(options={})
      all(options).find_all{|co|
        co.is_unused_credit?}
    end

    def current
      first(:conditions=>{:workflow_state=>['new']})
    end
  end
  has_one   :reseller, :dependent => :destroy
  accepts_nested_attributes_for :reseller, :allow_destroy=>false
  has_one   :affiliate, :dependent => :destroy
  has_one   :contact, :as => :contactable
  has_one   :funded_account, :dependent => :destroy
  has_many  :orders, :as=>:billable, :after_add=>:build_line_items do
    def not_new(options=nil)
      includes(:line_items).all(options || {}).
        find_all do |o|
          co=o.line_items.map(&:sellable).flatten.uniq.last
          if co
            if co.class == CertificateOrder && co.workflow_state!='paid' &&
              ['new'].include?(co.certificate_content.workflow_state)
              false
            else
              true
            end
          end
      end
    end
  end
  
  unless MIGRATING_FROM_LEGACY
    #has_many  :orders, :as=>:billable, :after_add=>:build_line_items
    attr_readonly :acct_number
  end

  preference  :reminder_notice_triggers, :string
  preference  :reminder_include_reseller, :default=>true
  preference  :reminder_notice_destinations, :string, :default=>"0"
  preference  :reminder_include_cert_admin, :default=>:determine_default_pref
  preference  :reminder_include_cert_tech, :default=>:determine_default_pref
  preference  :processed_include_reseller, :default=>true
  preference  :processed_certificate_recipients, :string, :default=>"0"
  preference  :processed_include_cert_admin, :string, :default=>:determine_default_pref
  preference  :processed_include_cert_tech, :string, :default=>:determine_default_pref
  preference  :processed_include_reseller, :default=>true
  preference  :receipt_include_reseller, :default=>true
  preference  :receipt_recipients, :string, :default=>"0"
  preference  :receipt_include_cert_admin, :string, :default=>:determine_default_pref
  preference  :receipt_include_cert_bill, :string, :default=>:determine_default_pref
  preference  :confirmation_include_reseller, :default=>true
  preference  :confirmation_recipients, :string, :default=>"0"
  preference  :confirmation_include_cert_admin, :string, :default=>:determine_default_pref
  preference  :confirmation_include_cert_bill, :string, :default=>:determine_default_pref

  before_create :b_create
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
  validates_uniqueness_of :acct_number, :on=>:create

  default_scope :order => 'created_at DESC'

  def b_create
    self.acct_number='a'+ActiveSupport::SecureRandom.hex(1)+
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
  end

  def self.human_attribute_name(attr)
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
    top_paid.last(how_many).map{|s|s.users.last}

  end

  def self.top_paid_amounts(how_many=10)
    top_paid([:orders]).last(how_many).map(&:total_amount_paid).map(&:format)
  end

  def reseller_tier_label
    reseller.reseller_tier.label if has_role?('reseller')
  end

  def can_buy?(item)
    if item.reseller_tier.nil?
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

  def has_only_credits?
    certificate_orders.credits.count==certificate_orders.not_new.count
  end

  def has_credits?
    certificate_orders.unused_credits.count > 0
  end

  def has_certificate_orders?
    certificate_orders.not_new.count > 0
  end

  %W(receipt confirmation).each do |et|
    define_method("#{et}_recipients") do
      returning addys = [] do
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
  private

  SETTINGS_SECTIONS.each do |item|
    define_method("#{item}_recipients_format") do
      emails=[]
      emails = eval("preferred_#{item}_recipients.split(' ')") unless
        eval("preferred_#{item}_recipients.blank?")
      errors.add("preferred_#{item}_recipients".to_sym,
        'cannot be blank') if emails.empty?
      results = emails.reject do |email|
        email =~ /^([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})$/
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
      email =~ /^([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})$/
    end
    errors.add(:preferred_reminder_notice_destinations,
      'has invalid email addresses') unless (results.empty?)
  end

  def determine_default_pref
    not is_registered_reseller?
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
    if !order.new_record? && order.line_items.all? {|c|c.sellable.try(:is_prepaid?)}
      OrderNotifier.deliver_certificate_order_prepaid self, order
      order.line_items.each do |cert|
        self.certificate_orders << cert.sellable
        cert.sellable.pay! true
      end
    end
  end
end
