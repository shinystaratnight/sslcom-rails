class CertificateContent < ActiveRecord::Base
  include V2MigrationProgressAddon
  belongs_to  :certificate_order
  belongs_to  :server_software
  has_one     :csr
  has_one     :registrant, :as => :contactable
  has_many    :certificate_contacts, :as => :contactable

#  attr_accessible :certificate_contacts_attributes

  #before_update :delete_duplicate_contacts

  accepts_nested_attributes_for :certificate_contacts, :allow_destroy => true
  accepts_nested_attributes_for :registrant, :allow_destroy => false

  SIGNING_REQUEST_REGEX = /\A[\w\-\/\s\n\+=]+\Z/
  MIN_KEY_SIZE = 2047 #thought would be 2048, be see
    #http://groups.google.com/group/mozilla.dev.security.policy/browse_thread/thread/7ceb6dd787e20da3# for details
  NOT_VALID_ISO_CODE="is not a valid 2 lettered ISO-3166 country code."

  ADMINISTRATIVE_ROLE = 'administrative'
  CONTACT_ROLES = %w(administrative billing technical validation)

  RESELLER_FIELDS_TO_COPY = %w(first_name last_name
   po_box address1 address2 address3 city state postal_code email phone ext fax)

  #SSL.com=>Comodo
  COMODO_SERVER_SOFTWARE_MAPPINGS = {
      1=>-1, 2=>1, 3=>2, 4=>3, 5=>4, 6=>33, 7=>34, 8=>5,
      9=>6, 10=>29, 11=>32, 12=>7, 13=>8, 14=>9, 15=>10,
      16=>11, 17=>12, 18=>13, 19=>14, 20=>35, 21=>15,
      22=>16, 23=>17, 24=>18, 25=>30, 26=>19, 27=>20, 28=>21,
      29=>22, 30=>23, 31=>24, 32=>25, 33=>26, 34=>27, 35=>31, 36=>28, 37=>-1, 38=>-1, 39=>3}
  
  ICANN_TLDS = %w(AC ACADEMY ACCOUNTANTS ACTOR AD AE AERO AF AG AGENCY AI AIRFORCE AL AM AN AO AQ AR ARCHI ARPA AS
    ASIA ASSOCIATES AT AU AUDIO AUTOS AW AX AXA AZ BA BAR BARGAINS BAYERN BB BD BE BEER BERLIN BEST BF BG BH BI BID
    BIKE BIZ BJ BLACK BLACKFRIDAY BLUE BM BN BO BOUTIQUE BR BS BT BUILD BUILDERS BUZZ BV BW BY BZ CA CAB CAMERA CAMP
    CAPITAL CARDS CARE CAREER CAREERS CASH CAT CATERING CC CD CENTER CEO CF CG CH CHEAP CHRISTMAS CHURCH CI CITIC CK
    CL CLAIMS CLEANING CLINIC CLOTHING CLUB CM CN CO CODES COFFEE COLLEGE COLOGNE COM COMMUNITY COMPANY COMPUTER
    CONDOS CONSTRUCTION CONSULTING CONTRACTORS COOKING COOL COOP COUNTRY CR CREDIT CREDITCARD CRUISES CU CV CW CX CY
    CZ DANCE DATING DE DEMOCRAT DENTAL DESI DIAMONDS DIGITAL DIRECTORY DISCOUNT DJ DK DM DNP DO DOMAINS DZ EC EDU
    EDUCATION EE EG EMAIL ENGINEERING ENTERPRISES EQUIPMENT ER ES ESTATE ET EU EUS EVENTS EXCHANGE EXPERT EXPOSED
    FAIL FARM FEEDBACK FI FINANCE FINANCIAL FISH FISHING FITNESS FJ FK FLIGHTS FLORIST FM FO FOO FOUNDATION FR FROGANS
    FUND FURNITURE FUTBOL GA GAL GALLERY GB GD GE GF GG GH GI GIFT GL GLASS GLOBO GM GMO GN GOP GOV GP GQ GR GRAPHICS
    GRATIS GRIPE GS GT GU GUIDE GUITARS GURU GW GY HAUS HIPHOP HK HM HN HOLDINGS HOLIDAY HOMES HORSE HOUSE HR HT HU ID
    IE IL IM IMMOBILIEN IN INDUSTRIES INFO INK INSTITUTE INSURE INT INTERNATIONAL INVESTMENTS IO IQ IR IS IT JE JETZT
    JM JO JOBS JP JUEGOS KAUFEN KE KG KH KI KIM KITCHEN KIWI KM KN KOELN KP KR KRED KW KY KZ LA LAND LB LC LEASE LI
    LIFE LIGHTING LIMITED LIMO LINK LK LOANS LONDON LR LS LT LU LUXE LUXURY LV LY MA MAISON MANAGEMENT MANGO
    MARKETING MC MD ME MEDIA MEET MENU MG MH MIAMI MIL MK ML MM MN MO MOBI MODA MOE MONASH MOSCOW MOTORCYCLES MP MQ MR
    MS MT MU MUSEUM MV MW MX MY MZ NA NAGOYA NAME NC NE NET NEUSTAR NF NG NI NINJA NL NO NP NR NU NYC NZ OKINAWA OM
    ONL ORG PA PARIS PARTNERS PARTS PE PF PG PH PHOTO PHOTOGRAPHY PHOTOS PICS PICTURES PINK PK PL PLUMBING PM PN POST
    PR PRO PRODUCTIONS PROPERTIES PS PT PUB PW PY QA QPON QUEBEC RE RECIPES RED REISE REISEN REN RENTALS REPAIR
    REPORT REST REVIEWS RICH RIO RO ROCKS RODEO RS RU RUHR RW RYUKYU SA SAARLAND SB SC SCHULE SD SE SERVICES SEXY SG
    SH SHIKSHA SHOES SI SINGLES SJ SK SL SM SN SO SOCIAL SOHU SOLAR SOLUTIONS SOY SR ST SU SUPPLIES SUPPLY SUPPORT
    SURGERY SV SX SY SYSTEMS SZ TATTOO TAX TC TD TECHNOLOGY TEL TF TG TH TIENDA TIPS TJ TK TL TM TN TO TODAY TOKYO
    TOOLS TOWN TOYS TP TR TRADE TRAINING TRAVEL TT TV TW TZ UA UG UK UNIVERSITY UNO US UY UZ VA VACATIONS VC VE VEGAS
    VENTURES VERSICHERUNG VG VI VIAJES VILLAS VISION VN VODKA VOTE VOTING VOTO VOYAGE VU WANG WATCH WEBCAM WED WF WIEN
    WIKI WORKS WS WTC WTF XN--3BST00M XN--3DS443G XN--3E0B707E XN--45BRJ9C XN--4GBRIM XN--55QW42G XN--55QX5D
    XN--6FRZ82G XN--6QQ986B3XL XN--80ADXHKS XN--80AO21A XN--80ASEHDB XN--80ASWG XN--90A3AC XN--C1AVG XN--CG4BKI
    XN--CLCHC0EA0B2G2A9GCD XN--CZR694B XN--CZRU2D XN--D1ACJ3B XN--FIQ228C5HS XN--FIQ64B XN--FIQS8S XN--FIQZ9S
    XN--FPCRJ9C3D XN--FZC2C9E2C XN--GECRJ9C XN--H2BRJ9C XN--I1B6B1A6A2E XN--IO0A7I XN--J1AMH XN--J6W193G XN--KPRW13D
    XN--KPRY57D XN--L1ACC XN--LGBBAT1AD8J XN--MGB9AWBF XN--MGBA3A4F16A XN--MGBAAM7A8H XN--MGBAB2BD XN--MGBAYH7GPA
    XN--MGBBH1A71E XN--MGBC0A9AZCG XN--MGBERP4A5D4AR XN--MGBX4CD0AB XN--NGBC5AZD XN--NQV7F XN--NQV7FS00EMA XN--O3CW4H
    XN--OGBPF8FL XN--P1AI XN--PGBS0DH XN--Q9JYB4C XN--RHQV96G XN--S9BRJ9C XN--SES554G XN--UNUP4Y XN--WGBH1C XN--WGBL6A
    XN--XKC2AL3HYE2A XN--XKC2DL3A5EE0H XN--YFRO4I67O XN--YGBI2AMMX XN--ZFR164B XXX XYZ YACHTS YE YOKOHAMA YT ZA ZM
    ZONE ZW)

  INTRANET_IP_REGEX = /^(127\.0\.0\.1)|(10.\d{,3}.\d{,3}.\d{,3})|(172\.1[6-9].\d{,3}.\d{,3})|(172\.2[0-9].\d{,3}.\d{,3})|(172\.3[0-1].\d{,3}.\d{,3})|(192\.168.\d{,3}.\d{,3})$/

  TLD_REGEX = Regexp.new("\\.(#{ICANN_TLDS.join("|")})$", "i")

  serialize :domains

  #unless MIGRATING_FROM_LEGACY
  validates_presence_of :server_software_id, :signing_request,
    :if => "certificate_order_has_csr && !ajax_check_csr"
  validates_format_of :signing_request, :with=>SIGNING_REQUEST_REGEX,
    :message=> 'contains invalid characters.',
    :if => :certificate_order_has_csr_and_signing_request
  validate :domains_validation, :if=>"certificate_order.certificate.is_ucc?"
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
      event :pend_validation, :transitions_to => :pending_validation do |send_to_ca=true|
        if send_to_ca
          unless csr.sent_success #do not send if already sent successfully
            certificate_order.apply_for_certificate
            last_sent=csr.domain_control_validations.last_sent
            if last_sent
              certificate_order.receipt_recipients.uniq.each do |c|
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
      self.ajax_check_csr ||=false
    end
  end


  def domains=(domains)
    unless domains.blank?
      domains = domains.split(/\s+/).uniq.reject{|d|d.blank?}
    end
    write_attribute(:domains, domains)
  end

  def additional_domains=(html_domains)
    self.domains=html_domains
  end

  def additional_domains
    domains.join("\ ") unless domains.blank?
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
      ed < Settings.expiring_threshold.days.from_now
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

  def self.is_tld?(name)
    !!(name=~TLD_REGEX)
  end

  def self.is_intranet?(name)
    name=~/\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}/ ? !!(name=~INTRANET_IP_REGEX) : !is_tld?(name)
  end

  private

  def domains_validation
    is_wildcard = certificate_order.certificate.allow_wildcard_ucc?
    invalid_chars_msg = "domain has invalid characters. Only the following characters
      are allowed [A-Za-z0-9.-#{'*' if is_wildcard}] in the domain or subject"
    unless domains.blank?
      errors.add(:additional_domains, invalid_chars_msg) unless domains.reject{|domain|
        domain_validation_regex(is_wildcard, domain)}.empty?
    end
  end

  def csr_validation
    is_wildcard = certificate_order.certificate.is_wildcard?
    is_free = certificate_order.certificate.is_free?
    invalid_chars_msg = "domain has invalid characters. Only the following characters
          are allowed [A-Za-z0-9.-#{'*' if is_wildcard}] in the domain or subject"
    if csr.common_name.blank?
      errors.add(:signing_request, 'is missing the common name (CN) field or is invalid and cannot be parsed')
    else
      #errors.add(:signing_request, 'is missing the organization (O) field') if csr.organization.blank?
      asterisk_found = (csr.common_name=~/^\*\./)==0
      if is_wildcard && !asterisk_found
        errors.add(:signing_request, "is wildcard certificate order, so it must begin with *.")
      elsif !is_wildcard && asterisk_found
        errors.add(:signing_request,
          "cannot begin with *. since it is not a wildcard")
      elsif is_free && csr.is_intranet?
        errors.add(:signing_request,
          "was determined to be for an intranet or internal site. These can only be issued as High Assurance or EV certs..")
      elsif is_free && csr.is_ip_address?
        errors.add(:signing_request,
          "was determined to be for an ip address. These can only be issued as High Assurance or EV certs.")
      end
      errors.add(:signing_request, invalid_chars_msg) unless
        domain_validation_regex(is_wildcard, csr.read_attribute(:common_name).gsub(/\x00/, ''))
      errors.add(:signing_request, "must have a 2048 bit key size.
        Please submit a new ssl.com certificate signing request with the proper key size.") if
          csr.strength.blank? || (csr.strength < MIN_KEY_SIZE)
      #errors.add(:signing_request,
      #  "country code '#{csr.country}' #{NOT_VALID_ISO_CODE}") unless
      #    Country.accepted_countries.include?(csr.country)
    end
  end

  def domain_validation_regex(is_wildcard, domain)
    invalid_chars = "[^\\s\\n\\w\\.\\x00\\-#{'\\*' if is_wildcard}]"
    domain.index(Regexp.new(invalid_chars))==nil and
    domain.index(/\.\.+/)==nil and domain.index(/^\./)==nil and
    domain.index(/[^\w]$/)==nil and domain.index(/^[^\w\*]/)==nil and
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
