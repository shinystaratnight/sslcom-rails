class CertificateContent < ActiveRecord::Base
  include V2MigrationProgressAddon
  belongs_to  :certificate_order
  belongs_to  :server_software
  has_one     :csr
  has_one     :registrant, :as => :contactable
  has_many    :certificate_contacts, :as => :contactable
  has_many    :certificate_names # used for dcv of each domain in a UCC or multi domain ssl

  accepts_nested_attributes_for :certificate_contacts, :allow_destroy => true
  accepts_nested_attributes_for :registrant, :allow_destroy => false

  after_update :certificate_names_from_domains, :if => :domains_changed?

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
  
  ICANN_TLDS = %w(
    AC
    ACADEMY
    ACCOUNTANTS
    ACTIVE
    ACTOR
    AD
    AE
    AERO
    AF
    AG
    AGENCY
    AI
    AIRFORCE
    AL
    AM
    AN
    AO
    AQ
    AR
    ARCHI
    ARMY
    ARPA
    AS
    ASIA
    ASSOCIATES
    AT
    ATTORNEY
    AU
    AUCTION
    AUDIO
    AUTOS
    AW
    AX
    AXA
    AZ
    BA
    BAR
    BARGAINS
    BAYERN
    BB
    BD
    BE
    BEER
    BERLIN
    BEST
    BF
    BG
    BH
    BI
    BID
    BIKE
    BIO
    BIZ
    BJ
    BLACK
    BLACKFRIDAY
    BLUE
    BM
    BMW
    BN
    BNPPARIBAS
    BO
    BOO
    BOUTIQUE
    BR
    BRUSSELS
    BS
    BT
    BUILD
    BUILDERS
    BUSINESS
    BUZZ
    BV
    BW
    BY
    BZ
    BZH
    CA
    CAB
    CAL
    CAMERA
    CAMP
    CANCERRESEARCH
    CAPETOWN
    CAPITAL
    CARAVAN
    CARDS
    CARE
    CAREER
    CAREERS
    CASH
    CAT
    CATERING
    CC
    CD
    CENTER
    CEO
    CERN
    CF
    CG
    CH
    CHANNEL
    CHEAP
    CHRISTMAS
    CHROME
    CHURCH
    CI
    CITIC
    CITY
    CK
    CL
    CLAIMS
    CLEANING
    CLICK
    CLINIC
    CLOTHING
    CLUB
    CM
    CN
    CO
    CODES
    COFFEE
    COLLEGE
    COLOGNE
    COM
    COMMUNITY
    COMPANY
    COMPUTER
    CONDOS
    CONSTRUCTION
    CONSULTING
    CONTRACTORS
    COOKING
    COOL
    COOP
    COUNTRY
    CR
    CREDIT
    CREDITCARD
    CRUISES
    CU
    CUISINELLA
    CV
    CW
    CX
    CY
    CYMRU
    CZ
    DAD
    DANCE
    DATING
    DAY
    DE
    DEALS
    DEGREE
    DEMOCRAT
    DENTAL
    DENTIST
    DESI
    DIAMONDS
    DIET
    DIGITAL
    DIRECT
    DIRECTORY
    DISCOUNT
    DJ
    DK
    DM
    DNP
    DO
    DOMAINS
    DURBAN
    DZ
    EAT
    EC
    EDU
    EDUCATION
    EE
    EG
    EMAIL
    ENGINEER
    ENGINEERING
    ENTERPRISES
    EQUIPMENT
    ER
    ES
    ESQ
    ESTATE
    ET
    EU
    EUS
    EVENTS
    EXCHANGE
    EXPERT
    EXPOSED
    FAIL
    FARM
    FEEDBACK
    FI
    FINANCE
    FINANCIAL
    FISH
    FISHING
    FITNESS
    FJ
    FK
    FLIGHTS
    FLORIST
    FLY
    FM
    FO
    FOO
    FOUNDATION
    FR
    FRL
    FROGANS
    FUND
    FURNITURE
    FUTBOL
    GA
    GAL
    GALLERY
    GB
    GBIZ
    GD
    GE
    GENT
    GF
    GG
    GH
    GI
    GIFT
    GIFTS
    GIVES
    GL
    GLASS
    GLE
    GLOBAL
    GLOBO
    GM
    GMAIL
    GMO
    GMX
    GN
    GOOGLE
    GOP
    GOV
    GP
    GQ
    GR
    GRAPHICS
    GRATIS
    GREEN
    GRIPE
    GS
    GT
    GU
    GUIDE
    GUITARS
    GURU
    GW
    GY
    HAMBURG
    HAUS
    HEALTHCARE
    HELP
    HERE
    HIPHOP
    HIV
    HK
    HM
    HN
    HOLDINGS
    HOLIDAY
    HOMES
    HORSE
    HOST
    HOSTING
    HOUSE
    HOW
    HR
    HT
    HU
    ID
    IE
    IL
    IM
    IMMO
    IMMOBILIEN
    IN
    INDUSTRIES
    INFO
    ING
    INK
    INSTITUTE
    INSURE
    INT
    INTERNATIONAL
    INVESTMENTS
    IO
    IQ
    IR
    IS
    IT
    JE
    JETZT
    JM
    JO
    JOBS
    JOBURG
    JP
    JUEGOS
    KAUFEN
    KE
    KG
    KH
    KI
    KIM
    KITCHEN
    KIWI
    KM
    KN
    KOELN
    KP
    KR
    KRD
    KRED
    KW
    KY
    KZ
    LA
    LACAIXA
    LAND
    LAWYER
    LB
    LC
    LEASE
    LGBT
    LI
    LIFE
    LIGHTING
    LIMITED
    LIMO
    LINK
    LK
    LOANS
    LONDON
    LOTTO
    LR
    LS
    LT
    LTDA
    LU
    LUXE
    LUXURY
    LV
    LY
    MA
    MAISON
    MANAGEMENT
    MANGO
    MARKET
    MARKETING
    MC
    MD
    ME
    MEDIA
    MEET
    MELBOURNE
    MEME
    MENU
    MG
    MH
    MIAMI
    MIL
    MINI
    MK
    ML
    MM
    MN
    MO
    MOBI
    MODA
    MOE
    MONASH
    MORTGAGE
    MOSCOW
    MOTORCYCLES
    MOV
    MP
    MQ
    MR
    MS
    MT
    MU
    MUSEUM
    MV
    MW
    MX
    MY
    MZ
    NA
    NAGOYA
    NAME
    NAVY
    NC
    NE
    NET
    NETWORK
    NEUSTAR
    NEW
    NEXUS
    NF
    NG
    NGO
    NHK
    NI
    NINJA
    NL
    NO
    NP
    NR
    NRA
    NRW
    NU
    NYC
    NZ
    OKINAWA
    OM
    ONG
    ONL
    OOO
    ORG
    ORGANIC
    OTSUKA
    OVH
    PA
    PARIS
    PARTNERS
    PARTS
    PE
    PF
    PG
    PH
    PHARMACY
    PHOTO
    PHOTOGRAPHY
    PHOTOS
    PHYSIO
    PICS
    PICTURES
    PINK
    PIZZA
    PK
    PL
    PLACE
    PLUMBING
    PM
    PN
    POST
    PR
    PRAXI
    PRESS
    PRO
    PROD
    PRODUCTIONS
    PROF
    PROPERTIES
    PROPERTY
    PS
    PT
    PUB
    PW
    PY
    QA
    QPON
    QUEBEC
    RE
    REALTOR
    RECIPES
    RED
    REHAB
    REISE
    REISEN
    REN
    RENTALS
    REPAIR
    REPORT
    REPUBLICAN
    REST
    RESTAURANT
    REVIEWS
    RICH
    RIO
    RO
    ROCKS
    RODEO
    RS
    RSVP
    RU
    RUHR
    RW
    RYUKYU
    SA
    SAARLAND
    SARL
    SB
    SC
    SCA
    SCB
    SCHMIDT
    SCHULE
    SCOT
    SD
    SE
    SERVICES
    SEXY
    SG
    SH
    SHIKSHA
    SHOES
    SI
    SINGLES
    SJ
    SK
    SL
    SM
    SN
    SO
    SOCIAL
    SOFTWARE
    SOHU
    SOLAR
    SOLUTIONS
    SOY
    SPACE
    SPIEGEL
    SR
    ST
    SU
    SUPPLIES
    SUPPLY
    SUPPORT
    SURF
    SURGERY
    SUZUKI
    SV
    SX
    SY
    SYSTEMS
    SZ
    TATAR
    TATTOO
    TAX
    TC
    TD
    TECHNOLOGY
    TEL
    TF
    TG
    TH
    TIENDA
    TIPS
    TIROL
    TJ
    TK
    TL
    TM
    TN
    TO
    TODAY
    TOKYO
    TOOLS
    TOP
    TOWN
    TOYS
    TP
    TR
    TRADE
    TRAINING
    TRAVEL
    TT
    TV
    TW
    TZ
    UA
    UG
    UK
    UNIVERSITY
    UNO
    UOL
    US
    UY
    UZ
    VA
    VACATIONS
    VC
    VE
    VEGAS
    VENTURES
    VERSICHERUNG
    VET
    VG
    VI
    VIAJES
    VILLAS
    VISION
    VLAANDEREN
    VN
    VODKA
    VOTE
    VOTING
    VOTO
    VOYAGE
    VU
    WALES
    WANG
    WATCH
    WEBCAM
    WEBSITE
    WED
    WF
    WHOSWHO
    WIEN
    WIKI
    WILLIAMHILL
    WME
    WORKS
    WORLD
    WS
    WTC
    WTF
    XN--1QQW23A
    XN--3BST00M
    XN--3DS443G
    XN--3E0B707E
    XN--45BRJ9C
    XN--4GBRIM
    XN--55QW42G
    XN--55QX5D
    XN--6FRZ82G
    XN--6QQ986B3XL
    XN--80ADXHKS
    XN--80AO21A
    XN--80ASEHDB
    XN--80ASWG
    XN--90A3AC
    XN--C1AVG
    XN--CG4BKI
    XN--CLCHC0EA0B2G2A9GCD
    XN--CZR694B
    XN--CZRU2D
    XN--D1ACJ3B
    XN--FIQ228C5HS
    XN--FIQ64B
    XN--FIQS8S
    XN--FIQZ9S
    XN--FPCRJ9C3D
    XN--FZC2C9E2C
    XN--GECRJ9C
    XN--H2BRJ9C
    XN--I1B6B1A6A2E
    XN--IO0A7I
    XN--J1AMH
    XN--J6W193G
    XN--KPRW13D
    XN--KPRY57D
    XN--KPUT3I
    XN--L1ACC
    XN--LGBBAT1AD8J
    XN--MGB9AWBF
    XN--MGBA3A4F16A
    XN--MGBAAM7A8H
    XN--MGBAB2BD
    XN--MGBAYH7GPA
    XN--MGBBH1A71E
    XN--MGBC0A9AZCG
    XN--MGBERP4A5D4AR
    XN--MGBX4CD0AB
    XN--NGBC5AZD
    XN--NQV7F
    XN--NQV7FS00EMA
    XN--O3CW4H
    XN--OGBPF8FL
    XN--P1AI
    XN--PGBS0DH
    XN--Q9JYB4C
    XN--RHQV96G
    XN--S9BRJ9C
    XN--SES554G
    XN--UNUP4Y
    XN--VHQUV
    XN--WGBH1C
    XN--WGBL6A
    XN--XHQ521B
    XN--XKC2AL3HYE2A
    XN--XKC2DL3A5EE0H
    XN--YFRO4I67O
    XN--YGBI2AMMX
    XN--ZFR164B
    XXX
    XYZ
    YACHTS
    YANDEX
    YE
    YOKOHAMA
    YOUTUBE
    YT
    ZA
    ZIP
    ZM
    ZONE
    ZW
    )

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
            last_sent=unless certificate_order.certificate.is_ucc?
              csr.domain_control_validations.last_sent
            else
              certificate_names.map{|cn|cn.domain_control_validations.last_sent}.flatten.compact
            end
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

  def certificate_names_from_domains
    self.domains.flatten.each do |domain|
      certificate_names.create(name: domain) if certificate_names.find_by_name(domain).blank?
    end
    # delete orphaned certificate_names
    certificate_names.map(&:name).each do |cn|
      certificate_names.find_by_name(cn).destroy unless domains.flatten.include?(cn)
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

  def dcv_domains(options)
    i=0
    options[:domains].each do |k,v|
      case v
        when /https?/i, /cname/i
          self.certificate_names.create(name: k).
              domain_control_validations.create(dcv_method: v, candidate_addresses: options[:emails][k])
          self.csr.domain_control_validations.
              create(dcv_method: v, candidate_addresses: options[:emails][k]) if(i==0 && !certificate_order.certificate.is_ucc?)
        else
          self.certificate_names.create(name: k).
              domain_control_validations.create(dcv_method: "email", email_address: v, candidate_addresses: options[:emails][k])
          self.csr.domain_control_validations.
              create(dcv_method: "email", email_address: v, candidate_addresses: options[:emails][k]) if(i==0 && !certificate_order.certificate.is_ucc?)
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
    is_ucc = certificate_order.certificate.is_ucc?
    is_premium_ssl = certificate_order.certificate.is_premium_ssl?
    invalid_chars_msg = "domain has invalid characters. Only the following characters
          are allowed [A-Za-z0-9.-#{'*' if is_wildcard}] in the domain or subject"
    if csr.common_name.blank?
      errors.add(:signing_request, 'is missing the common name (CN) field or is invalid and cannot be parsed')
    else
      #errors.add(:signing_request, 'is missing the organization (O) field') if csr.organization.blank?
      asterisk_found = (csr.common_name=~/^\*\./)==0
      if is_wildcard && !asterisk_found
        errors.add(:signing_request, "is wildcard certificate order, so it must begin with *.")
      elsif ((!is_ucc && !is_wildcard) || is_premium_ssl) && asterisk_found
        errors.add(:signing_request,
          "cannot begin with *. since the order does not allow wildcards")
      elsif csr.is_intranet?
        errors.add(:signing_request,
          "was determined to be for an intranet or internal site. These have been phased out and are no longer allowed.")
      elsif is_free && csr.is_ip_address?
        errors.add(:signing_request,
          "was determined to be for an ip address. These can only be issued as High Assurance or EV certs.")
      end
      errors.add(:signing_request, invalid_chars_msg) unless
        domain_validation_regex(is_wildcard || (is_ucc && !is_premium_ssl), csr.read_attribute(:common_name).gsub(/\x00/, ''))
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
