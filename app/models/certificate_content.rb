class CertificateContent < ActiveRecord::Base
  include V2MigrationProgressAddon
  belongs_to  :certificate_order, -> { unscope(where: [:workflow_state, :is_expired]) }
  has_one     :ssl_account, through: :certificate_order
  has_many    :users, through: :certificate_order
  belongs_to  :server_software
  has_one     :csr, :dependent => :destroy
  has_many    :signed_certificates, through: :csr
  has_one     :registrant, :as => :contactable
  has_many    :certificate_contacts, :as => :contactable
  has_many    :certificate_names # used for dcv of each domain in a UCC or multi domain ssl

  accepts_nested_attributes_for :certificate_contacts, :allow_destroy => true
  accepts_nested_attributes_for :registrant, :allow_destroy => false

  after_update :certificate_names_from_domains

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

  TRADEMARKS = %w(whatsapp google apple paypal github amazon cloudapp microsoft amzn ssltools certchat certlock *.*.com
    *.*.org *.10million.org *.android.com *.aol.com *.azadegi.com *.balatarin.com *.comodo.com *.digicert.com
    *.globalsign.com *.google.com *.JanamFadayeRahbar.com *.logmein.com *.microsoft.com *.mossad.gov.il
    *.mozilla.org *.RamzShekaneBozorg.com *.SahebeDonyayeDigital.com *.skype.com *.startssl.com
    *.thawte.com *.torproject.org *.walla.co.il *.windowsupdate.com *.wordpress.com addons.mozilla.org
    azadegi.com Comodo\ Root\ CA CyberTrust\ Root\ CA DigiCert\ Root\ CA Equifax\ Root\ CA friends.walla.co.il
    GlobalSign\ Root\ CA login.live.com login.yahoo.com my.screenname.aol.com secure.logmein.com
    Thawte\ Root\ CA twitter.com VeriSign\ Root\ CA wordpress.com www.10million.org www.balatarin.com
    cia.gov cybertrust.com equifax.com facebook.com globalsign.com ssl.com
    google.com hamdami.com mossad.gov.il sis.gov.uk microsoft.com google.com
    yahoo.com login.yahoo.com login.skype.com mozilla.org live.com global\ trustee)

  #SSL.com=>Comodo
  COMODO_SERVER_SOFTWARE_MAPPINGS = {
      1=>-1, 2=>1, 3=>2, 4=>3, 5=>4, 6=>33, 7=>34, 8=>5,
      9=>6, 10=>29, 11=>32, 12=>7, 13=>8, 14=>9, 15=>10,
      16=>11, 17=>12, 18=>13, 19=>14, 20=>35, 21=>15,
      22=>16, 23=>17, 24=>18, 25=>30, 26=>19, 27=>20, 28=>21,
      29=>22, 30=>23, 31=>24, 32=>25, 33=>26, 34=>27, 35=>31, 36=>28, 37=>-1, 38=>-1, 39=>3}

  INTRANET_IP_REGEX = /\A(127\.0\.0\.1)|(10.\d{,3}.\d{,3}.\d{,3})|(172\.1[6-9].\d{,3}.\d{,3})|(172\.2[0-9].\d{,3}.\d{,3})|(172\.3[0-1].\d{,3}.\d{,3})|(192\.168.\d{,3}.\d{,3})\z/

  serialize :domains

  #unless MIGRATING_FROM_LEGACY
  validates_presence_of :server_software_id, :signing_request,
    :if => "certificate_order_has_csr && !ajax_check_csr"
  validates_format_of :signing_request, :with=>SIGNING_REQUEST_REGEX,
    :message=> 'contains invalid characters.',
    :if => :certificate_order_has_csr_and_signing_request
  validate :domains_validation
  validate :csr_validation, :if=>"new? && csr"
  #end

  attr_accessor  :additional_domains #used to html format results to page
  attr_accessor  :ajax_check_csr

  preference  :reprocessing, default: false

  include Workflow
  workflow do
    state :new do
      event :submit_csr, :transitions_to => :csr_submitted
      event :cancel, :transitions_to => :canceled
      event :issue, :transitions_to => :issued
      event :reset, :transitions_to => :new
    end

    state :csr_submitted do
      event :provide_info, :transitions_to => :info_provided
      event :reprocess, :transitions_to => :reprocess_requested
      event :cancel, :transitions_to => :canceled
      event :reset, :transitions_to => :new
    end

    state :info_provided do
      event :issue, :transitions_to => :issued
      event :provide_contacts, :transitions_to => :contacts_provided
      event :cancel, :transitions_to => :canceled
      event :reset, :transitions_to => :new
    end

    state :contacts_provided do
      event :issue, :transitions_to => :issued
      event :pend_validation, :transitions_to => :pending_validation do |options={}|
        unless csr.sent_success #do not send if already sent successfully
          options[:certificate_content]=self
          unless self.infringement.empty? # possible trademark problems
            OrderNotifier.potential_trademark(Settings.notify_address, certificate_order, self.infringement).deliver
          else
            certificate_order.apply_for_certificate(options)
          end
          last_sent=unless certificate_order.certificate.is_ucc?
            csr.domain_control_validations.last_sent
          else
            certificate_names.map{|cn|cn.domain_control_validations.last_sent}.flatten.compact
          end
          if last_sent
            certificate_order.valid_recipients_list.each do |c|
              OrderNotifier.dcv_sent(c,certificate_order,last_sent).deliver!
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
    if domains.blank?
      if csr && certificate_names.find_by_name(csr.common_name).blank?
        certificate_names.create(name: csr.common_name, is_common_name: true)
      end
    else
      domains.flatten.each_with_index do |domain, i|
        if certificate_names.find_by_name(domain).blank?
          certificate_names.create(name: domain, is_common_name: (i == 0)) 
        end
      end
    end
  end

  def signed_certificate
    signed_certificates.last
  end

  def domains=(names)
    unless names.blank?
      names = names.split(/\s+/).flatten.uniq.reject{|d|d.blank?}
    end
    write_attribute(:domains, names)
  end

  # are any of the sub/domains trademarks?
  def infringement
    return all_domains.map{|domain|domain if TRADEMARKS.any?{|trademark|trademark.downcase.in? domain.downcase}}.compact
  end

  def self.infringers
    CertificateContent.find_all{|cc|!cc.infringement.empty?}
  end

  def domains
    (read_attribute(:domains).kind_of?(Array) && read_attribute(:domains).flatten==["0"]) ? [] : read_attribute(:domains)
  end

  def additional_domains=(html_domains)
    self.domains=html_domains
  end

  def additional_domains
    domains.join("\ ") unless domains.blank?
  end

  def all_domains
    (certificate_names.map(&:name)+[csr.try(:common_name)]+(domains.blank? ? [] : domains)).flatten.uniq.compact
  end

  def certificate_names_by_domains
    all_domains.map{|d|certificate_names.find_by_name(d)}.compact
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
    COMODO_SERVER_SOFTWARE_MAPPINGS[server_software.id]
  end

  def has_all_contacts?
    CONTACT_ROLES.all? do |role|
      send "#{role}_contact"
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

  def contacts_for_form
    unless self.certificate_contacts.blank?
      CertificateContent::CONTACT_ROLES.map{|role|self.send "#{role}_contact"}
    else
      [].tap{|c_tmp|CertificateContent::CONTACT_ROLES.each {|r|
        c_tmp << CertificateContact.new(contactable: self, country: self.registrant.country, roles: [r])}}
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

  private

  def domains_validation
    unless all_domains.blank?
      all_domains.each do |domain|
        domain_validation(domain)
      end
    end
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
