# == Schema Information
#
# Table name: certificate_contents
#
#  id                   :integer          not null, primary key
#  agreement            :boolean
#  approval             :string(255)
#  billing_checkbox     :boolean
#  domains              :text(65535)
#  duration             :integer
#  ext_customer_ref     :string(255)
#  label                :string(255)
#  ref                  :string(255)
#  signed_certificate   :text(65535)
#  signing_request      :text(65535)
#  technical_checkbox   :boolean
#  validation_checkbox  :boolean
#  workflow_state       :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  ca_id                :integer
#  certificate_order_id :integer          not null
#  server_software_id   :integer
#
# Indexes
#
#  index_certificate_contents_on_ca_id                 (ca_id)
#  index_certificate_contents_on_certificate_order_id  (certificate_order_id)
#  index_certificate_contents_on_ref                   (ref)
#  index_certificate_contents_on_server_software_id    (server_software_id)
#  index_certificate_contents_on_workflow_state        (workflow_state)
#

class CertificateContent < ApplicationRecord
  extend Memoist
  include V2MigrationProgressAddon
  include Workflow
  include Concerns::CertificateContent
  include Concerns::CertificateContent::Association
  include Concerns::CertificateContent::Callbacks
  include Concerns::CertificateContent::Validations
  include Concerns::CertificateContent::Workflow

  serialize :domains

  attr_accessor  :additional_domains # used to html format results to page
  attr_accessor  :ajax_check_csr
  attr_accessor  :rekey_certificate
  attr_accessor  :skip_validation

  @@cli_domain = 'https://sws.sslpki.com'

  preference  :reprocessing, default: false
  preference  :pending_issuance, default: false
  preference  :process_pending_server_certificates, default: true

  CertificateNamesJob = Struct.new(:cc_id, :domains) do
    def perform
      CertificateContent.find_by_id(cc_id).certificate_names_from_domains
    end
  end

  validate :validate_blocklist, unless: Proc.new { |record| record.certificate_order.new_record? || record.skip_validation }

  def validate_blocklist
    offenses = Pillar::Authority::BlocklistEntry.matches?(self, ssl_account&.id)
    valid = true

    unless offenses.empty?
      offenses.each do |offense|
        if offense[:type] == "Pillar::Authority::BlocklistEntryTypes::Blacklist"
          offense[:matches].each do |match|
            errors.add(:base, "The field #{match[:field]} with value #{match[:value]} matches an entry in our blacklist database")
            valid = false
          end
        end
      end
    end

    valid
  end

  def pre_validation(options)
    if csr and !csr.sent_success #do not send if already sent successfully
      options[:certificate_content] = self
      if !self.infringement.empty? # possible trademark problems
        OrderNotifier.potential_trademark(Settings.notify_address, certificate_order, self.infringement).deliver_now
      elsif ca.blank?
        certificate_order.apply_for_certificate(options)
      end
      if options[:host]
        Delayed::Job.enqueue DcvSentNotifyJob.new(id, options[:host])
      else
        last_sent = unless certificate_order.certificate.is_ucc?
                      csr.domain_control_validations.last_sent
                    else
                      certificate_names.map {|cn| cn.last_sent_domain_control_validations.last}.flatten.compact
                    end
        unless last_sent.blank?
          certificate_order.valid_recipients_list.each do |c|
            OrderNotifier.dcv_sent(c, certificate_order, last_sent).deliver!
          end
        end
      end
    end
  end

  def toggle_pending_issuance(status=nil)
    if status == false or (status.blank? and preferred_pending_issuance?)
      write_preference('pending_issuance', false)
    else
      write_preference('pending_issuance', true)
    end
    preferred_pending_issuance_will_change!
  end

  def add_ca(ssl_account)
    unless COMODO_SSL_ACCOUNTS.include?(ssl_account.id)
      self.ca = (self.certificate.cas.ssl_account_or_general_default(ssl_account)).last if ca.blank? and certificate
    end
  end

  def certificate_names_from_domains(domains=nil)
    is_single = certificate&.is_single?
    csr_common_name=csr.try(:common_name)
    unless (is_single || certificate&.is_wildcard?) && certificate_names.count.positive?
      domains ||= all_domains
      domains = domains.each{|domain| is_single ? CertificateContent.non_wildcard_name(domain,true) :
                                          domain.downcase}.uniq
      new_certificate_names=[]
      (domains-certificate_names.find_by_domains(domains).pluck(:name)).each do |domain|
        unless domain=~/,/
          new_certificate_names << certificate_names.new(name: domain, is_common_name: csr_common_name==domain)
        end
      end
      CertificateName.import new_certificate_names
      cns=certificate_names.where(name: new_certificate_names.map(&:name))
      unless cns.blank?
        cns.each do |cn|
          cn.candidate_email_addresses # start the queued job running
        end
        Delayed::Job.enqueue OtherDcvsSatisfyJob.new(ssl_account, cns, self, 'dv_only') if ssl_account && certificate&.is_server?
      end
    end
    # Auto adding domains in case of certificate order has been included into some groups.
    NotificationGroup.auto_manage_cert_name(self, 'create')
  end

  def all_domains_validated?
    !certificate_names.empty? && (certificate_names.pluck(:id) - certificate_names.validated.pluck(:id)).empty?
  end

  # TODO all methods check http, https, and cname
  def dcv_verify_certificate_names
    certificate_names.includes(:domain_control_validation).unvalidated.each do |cn|
      dcv = cn.domain_control_validation
      if dcv and cn.dcv_verify(dcv.dcv_method)
        dcv.satisfy!
      end
    end
  end

  def signed_certificate
    SignedCertificate.unscoped.find_by_id(Rails.cache.fetch("#{cache_key}/signed_certificate") do
      signed_certificates.last.try(:id)
    end)
  end
  memoize :signed_certificate

  def attestation_certificate
    attestation_certificates.last
  end

  def attestation_issuer_certificate
    attestation_issuer_certificates.last
  end

  def sslcom_ca_request
    SslcomCaRequest.where(username: self.label).first
  end

  # this hash is used for filenames based on many domains
  def domains_hash
    Digest::SHA1.hexdigest(domains.join(","))
  end

  def pkcs7
    sslcom_ca_request.pkcs7
  end

  def x509_certificates
    sslcom_ca_request.try(:x509_certificates)
  end

  def certificate_chain
    sslcom_ca_request.certificate_chain
  end

  # :with_tags (default), :x509, :without_tags
  def ejbca_certificate_chain(options={format: :with_tags})
    chain=sslcom_ca_request
    xcert=Certificate.xcert_certum(chain.x509_certificates.last)
    certs=chain.x509_certificates
    if options[:format]==:objects
      xcert ? certs[0..-2]<<OpenSSL::X509::Certificate.new(SignedCertificate.enclose_with_tags(xcert)) : certs
    elsif options[:format]==:without_tags
      certs=chain.certificate_chain
      xcert ? certs[0..-2]<<SignedCertificate.remove_begin_end_tags(xcert).chop : certs
    else
      xcert ? certs[0..-2].map(&:to_s)<<SignedCertificate.enclose_with_tags(xcert) : certs.map(&:to_s)
    end unless chain.blank?
  end

  def certificate
    certificate_order.try :certificate
  end

  # validate all certificate_names based on a previous validation
  def validate_via_cname
    certificate_names.each{|cn|cn.validate_via_cname}
    ca=csrs.map{|c|c.signed_certificates.map(&:created_at)}.first.first
    domain_control_validations.update_all responded_at: ca, created_at: ca, updated_at: ca
  end

  def self.cli_domain=(cli_domain)
    @@cli_domain=cli_domain
  end

  def cli_domain
    @@cli_domain
  end

  def domains=(names)
    unless names.blank?
      names = names.split(Certificate::DOMAINS_TEXTAREA_SEPARATOR).flatten.reject{|d|d.blank?}.map(&:downcase).uniq
    end
    write_attribute(:domains, names)
  end

  # are any of the sub/domains trademarks?
  def infringement
    Pillar::Authority::BlocklistEntry.matches?(self, ssl_account.id)
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
    extract=->{parse_unique_domains((domains.blank? ? [] : domains) +
                                        [csr.try(:all_names)] + certificate_names.map(&:name))}
    if new_record?
      extract.call
    else
      Rails.cache.fetch("#{cache_key}/all_domains") do
        extract.call
      end
    end
  end

  def certificate_names_by_domains
    certificate_names.find_by_domains(all_domains).compact
  end

  def to_api_retrieve(result, options)
    result.order_date = self.certificate_order.created_at
    result.order_status = self.certificate_order.status
    result.registrant = registrant.to_api_query if registrant
    result.contacts = certificate_contacts if certificate_contacts
    #'validations' kept executing twice so it was renamed to 'validations_from_comodo'
    result.validations = result.validations_from_comodo(self) if self.certificate_order.external_order_number
    result.description = self.certificate_order.description
    result.product = self.certificate_order.certificate.api_product_code
    result.product_name = self.certificate_order.certificate.product
    result.subscriber_agreement =
        self.certificate_order.certificate.subscriber_agreement_content if result.show_subscriber_agreement =~ /[Yy]/
    result.external_order_number = self.certificate_order.ext_customer_ref
    result.server_software = self.certificate_order.server_software.id if self.certificate_order.server_software

    if self.certificate_order.certificate.is_ucc?
      result.domains_qty_purchased = self.certificate_order.purchased_domains('all').to_s
      result.wildcard_qty_purchased = self.certificate_order.purchased_domains('wildcard').to_s
    else
      result.domains_qty_purchased = "1"
      result.wildcard_qty_purchased = self.certificate_order.certificate.is_wildcard? ? "1" : "0"
    end

    if (signed_certificate && result.query_type != "order_status_only")
      result.certificates =
          case options[:format]
          when "end_entity"
            signed_certificate.x509_certificates.first.to_s
          when "nginx"
            signed_certificate.to_nginx(false,order: options[:order])
          else
            signed_certificate.to_format(response_type: result.response_type, #assume comodo issued cert
                                              response_encoding: result.response_encoding) || signed_certificate.to_nginx
          end
      result.common_name = signed_certificate.common_name
      result.subject_alternative_names = signed_certificate.subject_alternative_names
      result.effective_date = signed_certificate.effective_date
      result.expiration_date = signed_certificate.expiration_date
      result.algorithm = signed_certificate.is_SHA2? ? "SHA256" : "SHA1"
    elsif (self.csr)
      result.certificates = ""
      result.common_name = self.csr.common_name
    end
  end

  def to_api_query
   {}.tap do |result|
     %w(ref).each do |k,v|
       result.merge!({"#{k.to_sym}": self.send(k)})
     end
   end
  end

  def callback(packaged_cert=nil,options={})
    if packaged_cert.blank?
      cert = ApiCertificateRetrieve.new(query_type: "all_certificates")
      to_api_retrieve cert, format: "nginx"
      packaged_cert =
          Rabl::Renderer.json(cert,File.join("api","v1","api_certificate_requests", "show_v1_4"),
                              view_path: 'app/views', locals: {result:cert})
    end
    uc = unless options.blank?
      UrlCallback.new(options)
    else
      url_callbacks.last
    end
    uc.perform_callback(certificate_hook:packaged_cert) unless uc.blank?
  end

  def dcv_suffix
    ca_id ? I18n.t('labels.ssl_ca') : I18n.t('labels.comodo_ca')
  end

  def manually_validate_cname
    (certificate_names-certificate_names.validated).each do |name|
      p [name.name,name.dcv_verify("cname",ignore_unique_value: true)]
    end
  end

  def dcv_domains(options)
    i = 0
    dcvs = [] # bulk insert of dcv
    cn_ids = [] # need to touch certificate_names to bust cache since bulk insert skips callbacks
    certificate_names.find_by_domains(options[:domains].keys).
        includes(:validated_domain_control_validations).each do |name|
      cn_ids << name.id
      k, v = name.name, options[:domains][name.name]
      cur_email = options[:emails] ? options[:emails][k] : nil
      dcv = name.validated_domain_control_validations.last
      case v["dcv"]
      when /https?/i, /cname/i
        # do not create another instance if previous cname of http(s) instance exists
        if dcv.blank?
          dcv = name.domain_control_validations.new(
              dcv_method: v["dcv"],
              candidate_addresses: cur_email,
              failure_action: v["dcv_failure_action"]
          )
          dcvs << dcv
        end

        if (v["dcv_failure_action"]=="remove" || options[:dcv_failure_action]=="remove")
          found = dcv.verify_http_csr_hash
          self.domains.delete(k) unless found
        end
      else
        if DomainControlValidation.approved_email_address? CertificateName.candidate_email_addresses(
            name.non_wildcard_name), v["dcv"]
          dcvs << name.domain_control_validations.new(dcv_method: "email", email_address: v["dcv"],
                                                 failure_action: v["dcv_failure_action"],
                                                 candidate_addresses: CertificateName.candidate_email_addresses(
                                                     name.non_wildcard_name))
        end
      end
      i+=1
    end
    DomainControlValidation.import dcvs
    CertificateName.where(id: cn_ids).update_all updated_at: DateTime.now
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
    if new? || csr_submitted?
      false
    else
      true
    end
  end

  def validation_type
    (signed_certificate || certificate).validation_type
  end

  CONTACT_ROLES.each do |role|
    define_method("#{role}_contacts") do
      certificate_contacts.select{|c|c.has_role? role}
    end

    define_method("#{role}_contact") do
      send("#{role}_contacts").last
    end
  end

  def cached_certificate_order
    CertificateOrder.unscoped.find_by_id(Rails.cache.fetch("#{cache_key}/cached_certificate_order")do
      certificate_order.id
    end)
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

  def common_name
    (certificate_names.find_by_is_common_name(true).try(:name) ||
        certificate_names.last.try(:name) || csr.try(:common_name)).try(:downcase)
  end

  def has_all_contacts?
    if Contact.optional_contacts?
      if certificate_order.certificate.is_dv? and Settings.exempt_dv_contacts
        true
      else
        certificate_contacts.any?
      end
    else
      (certificate_contacts.map(&:roles).uniq-CertificateContent::CONTACT_ROLES).empty
    end
  end

  def domains_and_common_name
    domains.flatten.uniq+[certificate_order.common_name]
  end

  def self.is_tld?(name)
    DomainNameValidator.valid?(name.downcase) if name
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

  # TODO rename this to include www function, or break this up into 2 functions
  def self.non_wildcard_name(name,remove_www=false)
    name=name.gsub(/\A\*\./, "").downcase unless name.blank?
    remove_www ? name.gsub("www.", "") : name
  end

  def self.is_fqdn?(name)
    unless is_ip_address?(name) && is_server_name?(name)
      name.index(/\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/ix)==0
    end if name
  end

  def to_ref
    cc = certificate_order.certificate_contents.where.not(id: nil)
    index = if cc.empty?
      0
    else
      cc_ref=cc.order(:created_at).last.ref
      cc_ref.blank? ? 0 : cc_ref.split('-').last.to_i + 1
    end
    "#{certificate_order.ref}-#{index}"
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

  def emergency_contact_emails
    (certificate_order.ssl_account.get_account_admins.map(&:email) +
      [certificate_order.ssl_account.get_account_owner.email] +
      administrative_contacts.map(&:email) +
      technical_contacts.map(&:email)).compact.uniq
  end

  # each domain needs to go through this
  def domain_validation(domain)
    is_wildcard = certificate_order.certificate.allow_wildcard_ucc?
    is_ucc = certificate_order.certificate.is_ucc?
    is_server = certificate_order.certificate.is_server?
    is_premium_ssl = certificate_order.certificate.is_premium_ssl?
    invalid_chars_msg = "#{domain} has invalid characters. Only the following characters
          are allowed [A-Za-z0-9.-#{'*' if(is_ucc || is_wildcard)}] in the domain or subject"
    if CertificateContent.is_ip_address?(domain) && false # CertificateContent.is_intranet?(domain)
      errors.add(:domain, " #{domain} must be an Internet-accessible IP Address")
    else
      if is_server
        #errors.add(:signing_request, 'is missing the organization (O) field') if csr.organization.blank?
        asterisk_found = (domain=~/\A\*\./)==0
        if ((!is_ucc && !is_wildcard) || is_premium_ssl) && asterisk_found
          errors.add(:domain, "cannot begin with *. since the order does not allow wildcards")
        elsif (certificate_order.certificate.is_dv? || certificate_order.certificate.is_ev?) && CertificateContent.is_ip_address?(domain)
          errors.add(:domain, "#{domain} was determined to be for an ip address. This is only allowed on OV ssl orders.")
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
  # 4- End Entity Profile : EV_CS_CERT_EE and Certificate Profile: EV_RSA_CS_ULMT_CERT
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
  #  5- End Entity Profile : CS_CERT_EE and Certificate Profile: RSA_CS_ULMT_CERT
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

  def locked_subject_dn
    dn = []
    if locked_registrant
      dn << "CN=#{locked_registrant.company_name}" unless locked_registrant.company_name.blank?
      if !locked_registrant.company_name.blank? and (!locked_registrant.city.blank? or !locked_registrant.state.blank?)
        dn << "O=#{locked_registrant.company_name}"
      end
      dn << "OU=#{locked_registrant.department}" unless locked_registrant.department.blank?
      dn << "L=#{locked_registrant.city}" unless locked_registrant.city.blank?
      dn << "ST=#{locked_registrant.state}" unless locked_registrant.state.blank?
      dn << "C=#{locked_registrant.country}" unless locked_registrant.country.blank?
      # dn << "postalCode=#{locked_registrant.postal_code}" unless locked_registrant.postal_code.blank?
      dn.map{|d|d.gsub(/\\/,'\\\\').gsub(',','\,')}.join(",")
    end
  end

  def subject_dn(options={})
    cert = options[:certificate] || self.certificate
    dn=certificate.is_server? ? ["CN=#{options[:common_name] || common_name}"] : []
    dn << "emailAddress=#{certificate_order&.get_recipient&.email}" if certificate.is_smime? && certificate_order&.get_recipient&.email
    if certificate.is_smime_or_client? and !certificate.is_client_basic?
      person=certificate_order.locked_recipient
      dn << "CN=#{[person&.first_name,person&.last_name].join(" ").strip}"
    end
    if locked_registrant and !(options[:mapping] ? options[:mapping].try(:profile_name) =~ /DV/ : cert.is_dv?)
      # if ev or ov order, must have locked registrant
      dn= ["CN=#{locked_registrant.company_name}"] if certificate.is_code_signing?
      org=locked_registrant.company_name
      ou=locked_registrant.department
      state=locked_registrant.state
      city=locked_registrant.city
      country=locked_registrant.country
      # postal_code=locked_registrant.postal_code
      # postal_address=locked_registrant.po_box
      # street_address= [locked_registrant.address1,locked_registrant.address2,locked_registrant.address3].join(" ")
      dn << "O=#{org}" if !org.blank? and (!city.blank? or !state.blank?)
      dn << "OU=#{ou}" unless ou.blank?
      dn << "OU=#{locked_registrant.special_fields["entity_code"]}" if certificate.is_naesb? and
          !certificate_order.locked_registrant.special_fields.blank?
      dn << "C=#{country}"
      dn << "L=#{city}" unless city.blank?
      dn << "ST=#{state}" unless state.blank?
      # dn << "postalCode=#{postal_code}" unless postal_code.blank?
      # dn << "postalAddress=#{postal_address}" unless postal_address.blank?
      # dn << "streetAddress=#{street_address}" unless street_address.blank?
      if cert.is_ev? || cert.is_evcs?
        dn << "serialNumber=#{locked_registrant.company_number}"
        dn << "2.5.4.15=#{locked_registrant.business_category}"
        dn << "1.3.6.1.4.1.311.60.2.1.1=#{locked_registrant.incorporation_city}" unless locked_registrant.incorporation_city.blank?
        dn << "1.3.6.1.4.1.311.60.2.1.2=#{locked_registrant.incorporation_state}" unless locked_registrant.incorporation_state.blank?
        dn << "1.3.6.1.4.1.311.60.2.1.3=#{locked_registrant.incorporation_country}"
      end
    end

    dn << options[:custom_fields] if options[:custom_fields]
    dn_array = dn.map{ |d| d.gsub(/\\/, '\\\\').gsub(',', '\,') }

    if options[:format]=="hash"
      {}.tap do |h|
        dn_array.each do |member|
          hash_member = member.split('=')
          h.merge!(hash_member[0] => hash_member[1])
        end
      end
    else
      dn_array.join(',')
    end
  end

  def cached_csr_public_key_sha1
    Rails.cache.fetch("#{cache_key}/cached_csr_public_key_sha1") do
      csr.public_key_sha1
    end
  end

  def cached_csr_public_key_md5
    Rails.cache.fetch("#{cache_key}/cached_csr_public_key_md5") do
      csr.public_key_md5
    end
  end

  def csr_certificate_name
    begin
      if csr && certificate_names.find_by_name(csr.common_name).blank?
        certificate_names.update_all(is_common_name: false)
        certificate_names.create(name: csr.common_name, is_common_name: true)
      end
    rescue StandardError => e
      logger.error e.message
    end
  end

  def preserve_certificate_contacts
    cc = certificate_order.certificate_contents.where.not(id: id).last
    certificate_contacts.update_all(contactable_id: cc.id) unless cc.nil?
  end

  def sslcom_approval_ids
    sslcom_ca_requests.unexpired.map(&:approval_id)
  end

  # if a certificate_content has a signed_certificate and is validated, it's state should be changed to issued
  def self.sync_issued_state
    certificate_content = CertificateContent.includes(csr: :signed_certificates).where{(workflow_state=="validated") & (created_at > 120.days.ago)}
    certificate_content.map do |cc|
      cc.issue! if(cc.signed_certificate and cc.certificate.is_server?)
    end.compact
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
    is_ucc = certificate_order.certificate.is_ucc?
    is_server = certificate_order.certificate.is_server?
    if csr.common_name.blank?
      errors.add(:signing_request, 'is missing the common name (CN) field or is invalid and cannot be parsed')
    elsif csr.is_weak_key?
      errors.add(:signing_request, 'is a rejected Debian weak key')
    elsif !csr.verify_signature
      errors.add(:signing_request, 'has an invalid signature')
    else
      if is_server
        asterisk_found = (csr.common_name=~/\A\*\./)==0
        if is_wildcard && !asterisk_found
          errors.add(:signing_request, "is wildcard certificate order, so it must begin with *.")
        elsif ((!(is_ucc && allow_wildcard_ucc) && !is_wildcard)) && asterisk_found
          errors.add(:signing_request, "cannot begin with *. since the order does not allow wildcards")
        elsif !DomainNameValidator.valid?(csr.common_name)
          errors.add(:signing_request, "common name field is invalid")
        end
      end
      errors.add(:signing_request, "must be any of the following #{MIN_KEY_SIZE.join(', ')} key sizes.
        Please submit a new certificate signing request with the proper key size.") if
          csr.sig_alg=~/WithRSAEncryption/i && (csr.strength.blank? || !MIN_KEY_SIZE.include?(csr.strength))
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
    ['true',true].any?{|t|t==certificate_order.try(:has_csr)}
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

  def transfer_existing_contacts
    certificate_order.certificate_contacts
      .where.not(contactable_id: id)
      .update_all(contactable_id: id)

    Contact.clear_duplicate_co_contacts(certificate_order)

    if certificate_contacts.any? && info_provided?
      provide_contacts!
    end
  end
end
