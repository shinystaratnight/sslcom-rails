class CertificateContent < ActiveRecord::Base
  include V2MigrationProgressAddon
  include Workflow
  
  belongs_to  :certificate_order, -> { unscope(where: [:workflow_state, :is_expired]) }
  has_one     :ssl_account, through: :certificate_order
  has_one     :certificate, through: :certificate_order
  has_many    :users, through: :certificate_order
  belongs_to  :server_software
  has_one     :csr, :dependent => :destroy
  has_many    :signed_certificates, through: :csr
  has_one     :registrant, :as => :contactable
  has_many    :certificate_contacts, :as => :contactable
  has_many    :certificate_names # used for dcv of each domain in a UCC or multi domain ssl
  has_many    :url_callbacks, as: :callbackable

  accepts_nested_attributes_for :certificate_contacts, :allow_destroy => true
  accepts_nested_attributes_for :registrant, :allow_destroy => false
  accepts_nested_attributes_for :csr, :allow_destroy => false

  after_create :certificate_names_from_domains, unless: :certificate_names_created?
  after_save   :certificate_names_from_domains, unless: :certificate_names_created?

  SIGNING_REQUEST_REGEX = /\A[\w\-\/\s\n\+=]+\Z/
  MIN_KEY_SIZE = 2047 #thought would be 2048, be see
    #http://groups.google.com/group/mozilla.dev.security.policy/browse_thread/thread/7ceb6dd787e20da3# for details
  NOT_VALID_ISO_CODE="is not a valid 2 lettered ISO-3166 country code."

  ADMINISTRATIVE_ROLE = 'administrative'
  CONTACT_ROLES = %w(administrative billing technical validation)

  RESELLER_FIELDS_TO_COPY = %w(first_name last_name
    po_box address1 address2 address3 city state postal_code email phone ext fax)

  # terms in this list that are submitted as domains for an ssl will be kicked back
  BARRED_SSL_TERMS = %w(\A\. \.onion\z \.local\z)

  TRADEMARKS = %w(whatsapp google apple paypal github amazon cloudapp microsoft amzn ssltools certchat certlock \*\.\*\.com
    \*\.\*\.org \*\.10million\.org \*\.android\.com \*\.aol\.com \*\.azadegi\.com \*\.balatarin\.com \*\.comodo\.com \*\.digicert\.com
    \*\.globalsign\.com \*\.google\.com \*\.JanamFadayeRahbar\.com \*\.logmein\.com \*\.microsoft\.com \*\.mossad\.gov\.il
    \*\.mozilla\.org \*\.RamzShekaneBozorg\.com \*\.SahebeDonyayeDigital\.com \*\.skype\.com \*\.startssl\.com
    \*\.thawte\.com \*\.torproject\.org \*\.walla\.co\.il \*\.windowsupdate\.com \*\.wordpress\.com addons\.mozilla\.org
    azadegi\.com Comodo\sRoot\sCA CyberTrust\sRoot\sCA DigiCert\sRoot\sCA Equifax\sRoot\sCA friends\.walla\.co\.il
    GlobalSign\sRoot\sCA login\.live\.com login\.yahoo\.com my\.screenname\.aol\.com secure\.logmein\.com
    Thawte\sRoot\sCA twitter\.com VeriSign\sRoot\sCA wordpress\.com www\.10million\.org www\.balatarin\.com
    cia\.gov cybertrust\.com equifax\.com facebook\.com globalsign\.com (\.|^)ssl\.com$
    google\.com hamdami\.com mossad\.gov\.il sis\.gov\.uk microsoft\.com google\.com
    yahoo\.com login\.skype\.com mozilla\.org live\.com global\strustee)

  DOMAIN_COUNT_OFFLOAD=50

  #SSL.com=>Comodo
  COMODO_SERVER_SOFTWARE_MAPPINGS = {
      1=>-1, 2=>1, 3=>2, 4=>3, 5=>4, 6=>33, 7=>34, 8=>5,
      9=>6, 10=>29, 11=>32, 12=>7, 13=>8, 14=>9, 15=>10,
      16=>11, 17=>12, 18=>13, 19=>14, 20=>35, 21=>15,
      22=>16, 23=>17, 24=>18, 25=>30, 26=>19, 27=>20, 28=>21,
      29=>22, 30=>23, 31=>24, 32=>25, 33=>26, 34=>27, 35=>31, 36=>28, 37=>-1, 38=>-1, 39=>3}

  INTRANET_IP_REGEX = /\A(127\.0\.0\.1)|(10.\d{,3}.\d{,3}.\d{,3})|(172\.1[6-9].\d{,3}.\d{,3})|(172\.2[0-9].\d{,3}.\d{,3})|(172\.3[0-1].\d{,3}.\d{,3})|(192\.168.\d{,3}.\d{,3})\z/

  serialize :domains
  
  validates_presence_of :server_software_id, :signing_request, # :agreement, # need to test :agreement out on reprocess and api submits
    :if => "certificate_order_has_csr && !ajax_check_csr && Settings.require_server_software_w_csr_submit"
  validates_format_of :signing_request, :with=>SIGNING_REQUEST_REGEX,
    :message=> 'contains invalid characters.',
    :if => :certificate_order_has_csr_and_signing_request
  validate :domains_validation, if: :validate_domains?
  validate :csr_validation, if: "new? && csr"

  attr_accessor  :additional_domains #used to html format results to page
  attr_accessor  :ajax_check_csr
  attr_accessor  :rekey_certificate

  preference  :reprocessing, default: false
  
  CertificateNamesJob = Struct.new(:cc_id, :domains) do
    def perform
      cc = CertificateContent.find cc_id
      all_domains.flatten.each_with_index do |domain, i|
        if cc.certificate_names.find_by_name(domain).blank?
          cc.certificate_names.create(name: domain, is_common_name: cc.csr.try(:common_name)==domain)
        end
      end
    end
  end

  DcvSentNotifyJob = Struct.new(:cc_id, :host) do
    def perform
      cc = CertificateContent.find cc_id
      co = cc.certificate_order
      last_sent = unless co.certificate.is_ucc?
        cc.csr.domain_control_validations.last_sent
      else
        cc.certificate_names.map{|cn| cn.domain_control_validations.last_sent}
          .flatten.compact
      end
      unless last_sent.blank?
        co.valid_recipients_list.each do |c|
          OrderNotifier.dcv_sent(c, co, last_sent, host).deliver_now if host
        end
      end
    end
  end
  
  workflow do
    state :new do
      event :submit_csr, :transitions_to => :csr_submitted
      event :provide_info, :transitions_to => :info_provided
      event :cancel, :transitions_to => :canceled
      event :issue, :transitions_to => :issued
      event :reset, :transitions_to => :new
    end

    state :csr_submitted do
      event :issue, :transitions_to => :issued
      event :provide_info, :transitions_to => :info_provided
      event :reprocess, :transitions_to => :reprocess_requested
      event :cancel, :transitions_to => :canceled
      event :reset, :transitions_to => :new
    end

    state :info_provided do
      event :submit_csr, :transitions_to => :csr_submitted
      event :issue, :transitions_to => :issued
      event :provide_contacts, :transitions_to => :contacts_provided
      event :cancel, :transitions_to => :canceled
      event :reset, :transitions_to => :new
    end

    state :contacts_provided do
      event :submit_csr, :transitions_to => :csr_submitted
      event :issue, :transitions_to => :issued
      event :pend_validation, :transitions_to => :pending_validation do |options={}|
        if csr and !csr.sent_success #do not send if already sent successfully
          options[:certificate_content]=self
          unless self.infringement.empty? # possible trademark problems
            OrderNotifier.potential_trademark(Settings.notify_address, certificate_order, self.infringement).deliver_now
          else
            certificate_order.apply_for_certificate(options)
          end
          if options[:host]
            Delayed::Job.enqueue DcvSentNotifyJob.new(id, options[:host])
          else
            last_sent=unless certificate_order.certificate.is_ucc?
              csr.domain_control_validations.last_sent
            else
              certificate_names.map{|cn|cn.domain_control_validations.last_sent}.flatten.compact
            end
            unless last_sent.blank?
              certificate_order.valid_recipients_list.each do |c|
                OrderNotifier.dcv_sent(c,certificate_order,last_sent).deliver!
              end
            end
          end
        end
      end
      event :cancel, :transitions_to => :canceled
      event :reset, :transitions_to => :new
    end

    state :pending_validation do
      event :issue, :transitions_to => :issued
      event :validate, :transitions_to => :validated do
        self.preferred_reprocessing = false if self.preferred_reprocessing?
      end
      event :cancel, :transitions_to => :canceled
      event :reset, :transitions_to => :new
    end

    state :validated do
      event :pend_validation, :transitions_to => :pending_validation
      event :issue, :transitions_to => :issued
      event :cancel, :transitions_to => :canceled
      event :reset, :transitions_to => :new
    end

    state :issued do
      event :reprocess, :transitions_to => :csr_submitted
      event :cancel, :transitions_to => :canceled
      event :revoke, :transitions_to => :revoked
      event :issue, :transitions_to => :issued
      event :reset, :transitions_to => :new
    end

    state :canceled

    state :revoked
  end

  after_initialize do
    if new_record?
      self.ajax_check_csr ||= false
      self.signing_request ||= ""
    end
  end

  after_create do |cc|
    cc.update_column :ref, cc.to_ref
    cc.update_column :label, cc.to_ref
  end

  def certificate_names_from_domains
    if csr && certificate_names.find_by_name(csr.common_name).blank?
      certificate_names.create(name: csr.common_name, is_common_name: true)
    end
    if all_domains.length <= DOMAIN_COUNT_OFFLOAD
      all_domains.flatten.each_with_index do |domain, i|
        if certificate_names.find_by_name(domain).blank?
          certificate_names.create(name: domain, is_common_name: csr.try(:common_name)==domain)
        end
      end
    else
      all_domains.flatten.each_slice(100) do |domain_slice|
        Delayed::Job.enqueue CertificateNamesJob.new(id, domain_slice)
      end
    end
  end

  def signed_certificate
    signed_certificates.last
  end

  def certificate
    certificate_order.certificate
  end

  def domains=(names)
    unless names.blank?
      names = names.split(/\s+/).flatten.uniq.reject{|d|d.blank?}
    end
    write_attribute(:domains, names)
  end

  # are any of the sub/domains trademarks?
  def infringement
    return all_domains.map{|domain|domain if TRADEMARKS.any?{|trademark|
      domain.downcase =~ Regexp.new(trademark, Regexp::IGNORECASE)}}.compact
  end

  def self.infringers
    CertificateContent.find_all{|cc|!cc.infringement.empty?}
  end

  def domains
    cur_domains = read_attribute(:domains)
    if cur_domains.kind_of?(Array) && cur_domains.flatten==["0"]
      []
    else
      parse_unique_domains(cur_domains)
    end
  end

  def additional_domains=(html_domains)
    self.domains=html_domains
  end

  def additional_domains
    domains.join("\ ") unless domains.blank?
  end

  def all_domains
    parse_unique_domains(
      (domains.blank? ? [] : domains) + [csr.try(:all_names)] + certificate_names.map(&:name)
    )
  end

  def certificate_names_by_domains
    all_domains.map{|d|certificate_names.find_by_name(d)}.compact
  end

  def url_callback
    url_callbacks.last.perform_callback(certificate_hook:
          %x"#{certificate_order.to_api_string(action: "show", domain_override: "https://sws-test.sslpki.local:3000", show_credentials: true)}") unless url_callbacks.blank?
  end

  def dcv_domains(options)
    i=0
    options[:domains].each do |k,v|
      cur_email = options[:emails] ? options[:emails][k] : nil
      case v["dcv"]
        when /https?/i, /cname/i
          dcv=self.certificate_names.find_by_name(k).
              domain_control_validations.create(dcv_method: v["dcv"], candidate_addresses: cur_email,
                failure_action: v["dcv_failure_action"])
          if (v["dcv_failure_action"]=="remove" || options[:dcv_failure_action]=="remove")
            found=dcv.verify_http_csr_hash
            self.domains.delete(k) unless found
          end
          # assume the first name is the common name
          self.csr.domain_control_validations.
              create(dcv_method: v["dcv"], candidate_addresses: cur_email,
                failure_action: v["dcv_failure_action"]) if(i==0 && !certificate_order.certificate.is_ucc?)
        else
          self.certificate_names.find_by_name(k).
              domain_control_validations.create(dcv_method: "email", email_address: v["dcv"],
                failure_action: v["dcv_failure_action"], candidate_addresses: cur_email)
          # assume the first name is the common name
          self.csr.domain_control_validations.
              create(dcv_method: "email", email_address: v["dcv"],
                failure_action: v["dcv_failure_action"], candidate_addresses: cur_email) if(i==0 && !certificate_order.certificate.is_ucc?)
      end
      i+=1
    end
  end

  def signing_request=(signing_request)
    write_attribute(:signing_request, signing_request)
    if (signing_request=~SIGNING_REQUEST_REGEX)==0
      unless self.create_csr(:body=>signing_request)
        logger.error "error #{self.model_and_id}#signing_request saving #{signing_request}"
      end
    end
  end

  def migrated_from
    v=V2MigrationProgress.find_by_migratable(self, :all)
    v.map(&:source_obj) if v
  end

  def show_validation_view?
    if new? || csr_submitted? || info_provided? || contacts_provided?
      return false
    end
    true
  end

  def validation_type
    (signed_certificate || certificate).validation_type
  end

  CONTACT_ROLES.each do |role|
    define_method("#{role}_contacts") do
      certificate_contacts(true).select{|c|c.has_role? role}
    end

    define_method("#{role}_contact") do
      send("#{role}_contacts").last
    end
  end

  def expired?
    csr.signed_certificate.expired? if csr.try(:signed_certificate)
  end


  def expiring?
    if csr.try(:signed_certificate)
      ed=csr.signed_certificate.expiration_date
      ed < Settings.expiring_threshold.days.from_now unless ed.blank?
    end
  end

  #finds or creates a certificate lookup
  def self.public_cert(cn,port=443)
    return nil if is_intranet?
    context = OpenSSL::SSL::SSLContext.new
    begin
      timeout(10) do
        tcp_client = TCPSocket.new cn, port
        ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
        ssl_client.connect
        cert=ssl_client.peer_cert
        CertificateLookup.create(
          certificate: cert.to_s,
          serial: cert.serial,
          expires_at: cert.not_after,
          common_name: cn) unless CertificateLookup.find_by_serial(cert.serial)
        cert
      end
    rescue Exception=>e
      nil
    end
  end

  def comodo_server_software_id
    COMODO_SERVER_SOFTWARE_MAPPINGS[server_software ? server_software.id : -1]
  end

  def has_all_contacts?
    if Contact.optional_contacts?
      if certificate_order.certificate.is_dv? and Settings.exempt_dv_contacts
        true
      else
        certificate_contacts.any?
      end
    else
      CertificateContent::CONTACT_ROLES.all? do |role|
        send "#{role}_contact"
      end
    end
  end

  def domains_and_common_name
    domains.flatten.uniq+[certificate_order.common_name]
  end

  def self.is_tld?(name)
    PublicSuffix.valid?(name.downcase) if name
  end

  def self.is_intranet?(name)
    (name=~/\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}/ ? is_intranet_ip?(name) : !is_tld?(name)) if name
  end

  def self.is_intranet_ip?(name)
    !!(name=~INTRANET_IP_REGEX) if name
  end

  def self.is_ip_address?(name)
    name.index(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/)==0 if name
  end

  def self.is_server_name?(name)
    name.index(/\./)==nil if name
  end

  def self.top_level_domain(name)
    if is_fqdn?(name)
      name=~(/(?:.*?\.)(.+)/)
      $1
    end
  end

  def self.non_wildcard_name(name)
    name.gsub(/\A\*\./, "").downcase unless name.blank?
  end

  def self.is_fqdn?(name)
    unless is_ip_address?(name) && is_server_name?(name)
      name.index(/\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/ix)==0
    end if name
  end

  def to_ref
    # "cc-"+created_at.to_i.to_s(16)
    certificate_order.ref+"-"+certificate_order.certificate_contents.index(self).to_s
  end
  
  def contacts_for_form_opt(type=nil)
      certificate_contact_compatibility
      case type
        when :custom   # contacts that are NOT duplicated from saved contacts
          certificate_contacts(true).select{|c| c.parent_id.nil? && c.type=='CertificateContact'}
        when :child    # contacts that were duplicated from saved contacts
          certificate_contacts(true).select{|c| !c.parent_id.nil? && c.type=='CertificateContact'}
        when :saved    # saved contacts for the team
          ssl_account.saved_contacts.select{|c| c.type=='CertificateContact'}
        when :selected # contacts, BOTH child and custom
          certificate_contacts(true).select{|c| c.type=='CertificateContact'}
        else
          []
      end
  end
  
  def contacts_for_form
    certificate_contact_compatibility
    unless self.certificate_contacts.blank?
      list  = CertificateContent::CONTACT_ROLES.map{|role|self.send "#{role}_contact"}.compact
      roles = list.map(&:roles).flatten.uniq
      CertificateContent::CONTACT_ROLES.each do |r|
        unless roles.include? r
          new_contact = CertificateContact.new(
            contactable: self, country: self.registrant.try(:country), roles: [r]
          )
          r == 'administrative' ? list.unshift(new_contact) : list.push(new_contact)
        end
      end
      list
    else
      [].tap{|c_tmp|CertificateContent::CONTACT_ROLES.each {|r|
        c_tmp << CertificateContact.new(contactable: self, country: self.registrant.try(:country), roles: [r])}}
    end
  end

  # each domain needs to go through this
  def domain_validation(domain)
    is_wildcard = certificate_order.certificate.allow_wildcard_ucc?
    is_free = certificate_order.certificate.is_free?
    is_ucc = certificate_order.certificate.is_ucc?
    is_code_signing = certificate_order.certificate.is_code_signing?
    is_client = certificate_order.certificate.is_client?
    is_premium_ssl = certificate_order.certificate.is_premium_ssl?
    invalid_chars_msg = "#{domain} has invalid characters. Only the following characters
          are allowed [A-Za-z0-9.-#{'*' if(is_ucc || is_wildcard)}] in the domain or subject"
    if CertificateContent.is_ip_address?(domain) && CertificateContent.is_intranet?(domain)
      errors.add(:domain, " #{domain} must be an Internet-accessible IP Address")
    else
      unless is_code_signing || is_client
        #errors.add(:signing_request, 'is missing the organization (O) field') if csr.organization.blank?
        asterisk_found = (domain=~/\A\*\./)==0
        if ((!is_ucc && !is_wildcard) || is_premium_ssl) && asterisk_found
          errors.add(:domain, "cannot begin with *. since the order does not allow wildcards")
        elsif CertificateContent.is_intranet?(domain)
          errors.add(:domain,
                     "#{domain} was determined to be for an intranet or internal site. These have been phased out and are no longer allowed.")
        elsif certificate_order.certificate.is_dv? && CertificateContent.is_ip_address?(domain)
          errors.add(:domain, "#{domain} was determined to be for an ip address. This is only allowed on OV or EV ssl orders.")
        elsif !!(domain=~Regexp.new("\\.("+Country::BLACKLIST.join("|")+")$",true))
          errors.add(:domain, "#{domain} is a restricted tld")
        end
        errors.add(:domain, invalid_chars_msg) unless
            domain_validation_regex(is_wildcard || (is_ucc && !is_premium_ssl), domain.gsub(/\x00/, ''))
        BARRED_SSL_TERMS.each do |barred|
          errors.add(:domain, "#{domain} contains non-compliant form") if domain =~ Regexp.new(barred)
        end
        errors.add(:domain, "#{domain} contains more than one * character") if (domain.scan /\*/).count > 1
        errors
      end
    end
  end

  def uniq_certificate_names
    certificate_names.pluck(:name).uniq.map{|c|certificate_names.order("created_at asc").find_by_name(c).id}
  end

  def dedupe_certificate_names
    CertificateName.delete(certificate_names.pluck(:id) - uniq_certificate_names)
  end
  # 1- End Entity Profile : DV_SERVER_CERT_EE and Certificate Profile: DV_RSA_SERVER_CERT
  #
  # Subject DN
  #
  # CN (Common name) - Required
  #
  # Subject Alternative Name
  #
  # dNSName - It could be multiple but atleast one is required
  #
  # 2- End Entity Profile : OV_SERVER_CERT_EE and Certificate Profile: OV_RSA_SERVER_CERT
  #
  # Subject DN
  #
  # CN (Common name) - Required
  # OU (Organizational Unit) - Optional
  # O (Organization) - Required
  # L (Locality) - Optional
  # ST (State or Province) - Optional
  # C (Country) - Required
  # postalCode - Optional
  # postalAddress - Optional
  # streetAddress - Optional
  #
  # Subject Alternative Name
  #
  # dNSName - It could be multiple but atleast one is required
  #
  # 3- End Entity Profile : EV_SERVER_CERT_EE and Certificate Profile: EV_RSA_SERVER_CERT
  #
  # Subject DN
  #
  # CN (Common name) - Required
  # OU (Organizational Unit) - Optional
  # O (Organization) - Required
  # L (Locality) - Optional
  # ST (State or Province) - Optional
  # C (Country) - Required
  # postalCode - Optional
  # postalAddress - Optional
  # streetAddress - Optional
  # 2.5.4.15 (businessCategory)- Required
  # serialNumber - Required
  # 1.3.6.1.4.1.311.60.2.1.1 (Jurisdiction Locality) - Optional
  # 1.3.6.1.4.1.311.60.2.1.2 (Jurisdiction State or Province) - Optional
  # 1.3.6.1.4.1.311.60.2.1.3 (Jurisdiction Country) - Required
  #
  # Subject Alternative Name
  #
  # dNSName - It could be multiple but atleast one is required
  #
  # 4- End Entity Profile : EV_CS_CERT_EE and Certificate Profile: EV_RSA_CS_CERT
  #
  # Subject DN
  #
  # CN (Common name) - Required
  # OU (Organizational Unit) - Optional
  # O (Organization) - Required
  # L (Locality) - Optional
  # ST (State or Province) - Optional
  # C (Country) - Required
  # postalCode - Optional
  # postalAddress - Optional
  # streetAddress - Optional
  # 2.5.4.15 (businessCategory)- Required
  # serialNumber - Required
  # 1.3.6.1.4.1.311.60.2.1.1 (Jurisdiction Locality) - Optional
  # 1.3.6.1.4.1.311.60.2.1.2 (Jurisdiction State or Province) - Optional
  # 1.3.6.1.4.1.311.60.2.1.3 (Jurisdiction Country) - Required
  #
  # Subject Alternative Name
  #
  # This extension is not required for this profile
  #
  #  5- End Entity Profile : CS_CERT_EE and Certificate Profile: RSA_CS_CERT
  #
  #  Subject DN
  #
  #  CN (Common name) - Required
  #  OU (Organizational Unit) - Optional
  #  O (Organization) - Required
  #  streetAddress - Optional
  #  L (Locality) - Optional
  #  ST (State or Province) - Optional
  #  postalCode - Optional
  #  C (Country) - Required
  #
  #  Subject Alternative Name
  #
  #
  #  Note:-
  #
  #  Subject DN format : "subject_dn": "CN=saad.com,O=SSL.COM,C=US". The names in open and closing parenthisis are just for description e.g. CN (common name). Here (common name) is for description. You only need to pass CN in subject DN. Those names that do not have any parenthisis will be passed as it is in subject DN.
  #      Subject alternative name format : "subject_alt_name": "dNSName=foo2.bar.com, dNSName=foo2.bar.com"

  def subject_dn(options={})
    cert = options[:certificate] || self.certificate
    dn=["CN=#{options[:common_name] || csr.common_name}"]
    unless cert.is_dv?
      dn << "O=#{options[:o] || registrant.company_name}"
      dn << "C=#{options[:c] || registrant.country}"
      if cert.is_ev?
        dn << "serialNumber=#{options[:serial_number] || certificate_order.jois.last.try(:company_number) ||
          ("11111111" if options[:ca_id]==Ca::ISSUER[:sslcom_shadow])}"
        dn << "2.5.4.15=#{options[:business_category] || certificate_order.jois.last.try(:business_category) ||
          ("Private Organization" if options[:ca_id]==Ca::ISSUER[:sslcom_shadow])}"
        dn << "1.3.6.1.4.1.311.60.2.1.1=#{options[:joi_locality] || certificate_order.jois.last.try(:city) ||
          ("Houston" if options[:ca_id]==Ca::ISSUER[:sslcom_shadow])}"
        dn << "1.3.6.1.4.1.311.60.2.1.2=#{options[:joi_state] || certificate_order.jois.last.try(:state) ||
          ("Texas" if options[:ca_id]==Ca::ISSUER[:sslcom_shadow])}"
        dn << "1.3.6.1.4.1.311.60.2.1.3=#{options[:joi_country] || certificate_order.jois.last.try(:country) ||
          ("US" if options[:ca_id]==Ca::ISSUER[:sslcom_shadow])}"
      end
    end
    dn << options[:custom_fields] if options[:custom_fields]
    dn.join(",")
  end

  def csr_certificate_name
    begin
      if csr and certificate_names.find_by_name(csr.common_name).blank?
        certificate_names.update_all(is_common_name: false)
        certificate_names.create(name: csr.common_name, is_common_name: true)
      end
    rescue
    end
  end

  private
  
  def certificate_contact_compatibility
    if Contact.optional_contacts? # optional contacts ENABLED
      # contacts created from saved contacts
      certificate_contacts(true).where(type: 'CertificateContact')
        .where.not(parent_id: nil).group_by(&:parent_id).each do |c_group|
          group = c_group.second
          if group.count > 1
            ids = group.map(&:id)
            certificate_contacts(true).find(ids.shift).update(roles: Contact.find(c_group.first).roles)
            certificate_contacts(true).where(id: ids).destroy_all
          end
        end
      # custom contacts, only created for this certificate content
      # convert 4 identical contacts into one w/role 'administrative'
      custom_contacts = certificate_contacts(true).where(type: 'CertificateContact', parent_id: nil)
      custom_contacts.each do |c|
        list = custom_contacts.where(c.attributes.keep_if {|k,_| Contact::SYNC_FIELDS_REQUIRED.include? k.to_sym})
        if list.count > 1
          found = list.first
          found.update(roles: ['administrative'])
          list.where.not(id: found.id).destroy_all
        end
      end
    else # Optional contacts DISABLED
      keep    = []
      updated = 0
      all     = certificate_contacts(true).where(type: 'CertificateContact')
      CertificateContent::CONTACT_ROLES.each do |role|
        found = certificate_contacts(true).where(type: 'CertificateContact')
          .where("roles LIKE ?", "%#{role}%")
        if found.any?
          update = found.first
          found = all - [update]
          if update.roles.count > 1
            update.update(roles: [role])
            updated += 1
          end
          keep << update
        end
      end
      if updated > 0
        self.update(billing_checkbox: 0, validation_checkbox: 0, technical_checkbox: 0)
      end
      all.where.not(id: keep.map(&:id)).destroy_all
    end
  end
  
  def validate_domains?
    (new? && (domains.blank? || errors[:domain].any?)) || !rekey_certificate.blank?
  end
  
  def certificate_names_created?
    self.reload
    return false if domains.blank? && !certificate_name_from_csr?
    new_domains     = parse_unique_domains(domains)
    current_domains = parse_unique_domains(certificate_names.pluck(:name))
    common          = current_domains & new_domains
    common.length == new_domains.length && (current_domains.length == new_domains.length)
  end
  
  def certificate_name_from_csr?
    certificate_names.count == 1 && 
      csr.common_name &&
      certificate_names.first.name == csr.common_name &&
      certificate_names.first.is_common_name
  end
  
  def parse_unique_domains(target_domains)
    return [] if target_domains.blank?
    target_domains.flatten.compact.map(&:downcase).map(&:strip).reject(&:blank?).uniq
  end
  
  def domains_validation
    unless all_domains.blank?
      all_domains.each do |domain|
        domain_validation(domain)
      end
    end
    self.rekey_certificate = false unless domains.blank?
  end

  def csr_validation
    allow_wildcard_ucc=certificate_order.certificate.allow_wildcard_ucc?
    is_wildcard = certificate_order.certificate.is_wildcard?
    is_free = certificate_order.certificate.is_free?
    is_ucc = certificate_order.certificate.is_ucc?
    is_code_signing = certificate_order.certificate.is_code_signing?
    is_client = certificate_order.certificate.is_client?
    is_premium_ssl = certificate_order.certificate.is_premium_ssl?
    invalid_chars_msg = "domain has invalid characters. Only the following characters
          are allowed [A-Za-z0-9.-#{'*' if(is_ucc || is_wildcard)}] in the subject"
    if csr.common_name.blank?
      errors.add(:signing_request, 'is missing the common name (CN) field or is invalid and cannot be parsed')
    else
      unless is_code_signing || is_client
        #errors.add(:signing_request, 'is missing the organization (O) field') if csr.organization.blank?
        asterisk_found = (csr.common_name=~/\A\*\./)==0
        if is_wildcard && !asterisk_found
          errors.add(:signing_request, "is wildcard certificate order, so it must begin with *.")
        elsif ((!(is_ucc && allow_wildcard_ucc) && !is_wildcard)) && asterisk_found
          errors.add(:signing_request, "cannot begin with *. since the order does not allow wildcards")
        end
      end
      errors.add(:signing_request, "must have a 2048 bit key size.
        Please submit a new ssl.com certificate signing request with the proper key size.") if
          csr.strength.blank? || (csr.strength < MIN_KEY_SIZE)
      #errors.add(:signing_request,
      #  "country code '#{csr.country}' #{NOT_VALID_ISO_CODE}") unless
      #    Country.accepted_countries.include?(csr.country)
    end
  end

  # This validates each domain entry in the CN and SAN fields
  def domain_validation_regex(is_wildcard, domain)
    invalid_chars = "[^\\s\\n\\w\\.\\x00\\-#{'\\*' if is_wildcard}]"
    domain.index(Regexp.new(invalid_chars))==nil and
    domain.index(/\.\.+/)==nil and domain.index(/\A\./)==nil and
    domain.index(/[^\w]\z/)==nil and domain.index(/\A[^\w\*]/)==nil and
      is_wildcard ? (domain.index(/(\w)\*/)==nil and
        domain.index(/(\*)[^\.]/)==nil) : true
  end

  def certificate_order_has_csr
    certificate_order.has_csr=='true' || certificate_order.has_csr==true
  end

  def certificate_order_has_csr_and_signing_request
    certificate_order_has_csr && !signing_request.blank?
  end

  def delete_duplicate_contacts
    CONTACT_ROLES.each do |role|
      contacts = send "#{role}_contacts"
      if contacts.count > 1
        contacts.shift
        contacts.each do |c|
          c.destroy
        end
      end
    end
    true
  end
end
