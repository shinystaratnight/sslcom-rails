require 'public_suffix'

class DomainControlValidation < ApplicationRecord
  has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  belongs_to  :csr, touch: true # only for single domain certs
  belongs_to  :csr_unique_value
  belongs_to  :certificate_name, touch: true  # only for UCC or multi domain certs
  delegate    :certificate_content, to: :csr
  # belongs_to :domain, class_name: "CertificateName"
  # delegate   :ssl_account, to: :domain
  serialize   :candidate_addresses
  belongs_to  :validation_compliance

  # validate  :email_address_check, unless: lambda{|r| r.email_address.blank?}

  IS_INVALID  = "is an invalid email address choice"
  FAILURE_ACTION = %w(ignore reject)
  AUTHORITY_EMAIL_ADDRESSES = %w(admin@ administrator@ webmaster@ hostmaster@ postmaster@)
  MAX_DURATION_DAYS={email: 820}

  EMAIL_CHOICE_CACHE_EXPIRES_DAYS=1

  default_scope{ order("domain_control_validations.created_at asc")}
  scope :global, -> {where{(certificate_name_id==nil) & (csr_id==nil)}}
  scope :whois_threshold, -> {where(updated_at: 1.hour.ago..DateTime.now)}
  scope :satisfied, -> {where(workflow_state: "satisfied")}

  after_initialize do
    # TODO: search for DomainControlValidation.generate_identifier and DRY the blocks up
    self.identifier ||= DomainControlValidation.generate_identifier
  end

  include Workflow
  workflow do
    state :new do
      event :send_dcv, :transitions_to => :sent_dcv
      event :hashing, :transitions_to => :hashed
      event :satisfy, :transitions_to => :satisfied
    end

    state :hashed do
      event :satisfy, :transitions_to => :satisfied
    end

    state :sent_dcv do
      event :satisfy, :transitions_to => :satisfied

      on_entry do
        self.update_attribute :sent_at, DateTime.now
      end
    end

    state :satisfied do
      on_entry do
        hash_satisfied unless dcv_method=~/email/
        self.validation_compliance_id=
          case dcv_method
          when /email/
            2
          when /http/
            6
          when /cname/
            7
          end
        self.identifier_found=true
        self.responded_at=DateTime.now
        self.save
      end
    end
  end

  def self.generate_identifier
    (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
  end

  def email_address_check
    errors.add(:email_address, "'#{email_address}' "+IS_INVALID) unless
        DomainControlValidation.approved_email_address? candidate_addresses, email_address
  end

  # use for notifying comodo order customers a dcv is on the way from Comodo
  def send_to(address)
    update_attributes email_address: address, sent_at: DateTime.now, dcv_method: "email"
    if csr.sent_success
      ComodoApi.auto_update_dcv(dcv: self)
      co=csr.certificate_content.certificate_order
      co.valid_recipients_list.each do |c|
        OrderNotifier.dcv_sent(c, co, self).deliver!
      end
    end
  end

  # assume this belongs to a certificate_name which belongs to an ssl_account
  def hash_satisfied
    prepend=""
    self.identifier,self.address_to_find_identifier= certificate_name.blank? ? [false,false] :
    case dcv_method
    when /https/
      ["#{certificate_name.csr.sha2_hash}\n#{certificate_name.ca_tag}#{"\n#{certificate_name.csr.unique_value}" unless
          certificate_name.csr.unique_value.blank?}",
       certificate_name.dcv_url(true,prepend, true)]
    when /http/
      ["#{certificate_name.csr.sha2_hash}\n#{certificate_name.ca_tag}#{"\n#{certificate_name.csr.unique_value}" unless certificate_name.csr.unique_value.blank?}",
       certificate_name.dcv_url(false,prepend, true)]
    when /cname/
      [certificate_name.cname_destination,
      certificate_name.cname_origin(true)]
    end
  end

  # the 24 hour limit no longer applies, but will keep this in case we need it again
  #def is_eligible_to_send?
  #  !email_address.blank? && updated_at > 24.hours.ago && !satisfied?
  #end

  def is_eligible_to_resend?
    !email_address.blank? && !satisfied?
  end
  alias :is_eligible_to_send? :is_eligible_to_resend?

  def method_for_api(options={http_csr_hash: "http_csr_hash", https_csr_hash: "https_csr_hash",
                              cname_csr_hash: "cname_csr_hash", email: self.email_address})
    case dcv_method
      when "http", "http_csr_hash"
        options[:http_csr_hash]
      when "https", "https_csr_hash"
        options[:https_csr_hash]
      when "cname", "cname_csr_hash"
        options[:cname_csr_hash]
      when "email"
        options[:email]
    end
  end

  def self.ssl_account(domain)
    SslAccount.unscoped.joins{certificate_names.domain_control_validations}.joins{certificate_contents.certificate_names.domain_control_validations}.where{(certificate_names.domain_control_validations.subject=~domain) or
        (certificate_contents.certificate_names.domain_control_validations.subject=~domain)}
  end

  def ssl_account
    SslAccount.unscoped.joins{domains.domain_control_validations.outer}.where(domain_control_validations: {id: self.id})
  end

  # this will find multi-level subdomains from a more root level domain
  def self.satisfied_validation(ssl_account,domain,public_key_sha1=nil)
    name=domain.downcase
    name=('%'+name[1..-1]) if name[0]=="*" # wildcard
    DomainControlValidation.joins(:certificate_name).where{(identifier_found==1) &
        (certificate_name.name=~"#{name}") &
        (certificate_name_id >> [ssl_account.all_certificate_names(name,"validated").pluck(:id)])}.each do |dcv|
          return dcv if dcv.validated?(name,public_key_sha1)
        end
  end

  def self.validated?(ssl_account,domain,public_key_sha1=nil)
    satisfied_validation(ssl_account,domain,public_key_sha1).blank? ? false : true
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

  # is this dcv validated?
  # domain - against a domain that may or many not be satisfied by this validation
  # public_key_sha1 - against a csr
  def validated?(domain=nil,public_key_sha1=nil)
    satisfied = ->(public_key_sha1){
        cert_req=(csr || certificate_name.csr).try(:public_key_sha1) if public_key_sha1
        identifier_found && !responded_at.blank? &&
            responded_at > DomainControlValidation::MAX_DURATION_DAYS[:email].days.ago &&
          (!email_address.blank? or (public_key_sha1 ?
                                         cert_req.try(:downcase)==public_key_sha1.downcase : true))
    }
    (domain ? DomainControlValidation.domain_in_subdomains?(domain,certificate_name.name) : true) and
        satisfied.call(public_key_sha1)
  end

  # this determines if a domain validation will satisfy another domain validation based on 2nd level subdomains and wildcards
  # BE VERY CAREFUL as this drives validation for the entire platform including Web and API
  def self.domain_in_subdomains?(subject,compare_with)
    subject=subject[2..-1] if subject=~/\A\*\./
    compare_with=compare_with[2..-1] if compare_with=~/\A\*\./
    if ::PublicSuffix.valid?(subject, default_rule: nil) and ::PublicSuffix.valid?(compare_with, default_rule: nil)
      d=::PublicSuffix.parse(compare_with)
      compare_with_subdomains = d.trd ? d.trd.split(".").reverse : []
      0.upto(compare_with_subdomains.count) do |i|
        return true if ((compare_with_subdomains.slice(0,i).reverse<<d.domain).join("."))==subject
      end
    end
    false
  end

  def verify_http_csr_hash
    certificate_name.dcv_verify(dcv_method)
  end

  def email_address_choices
    name = (csr.blank? ? certificate_name_id.nil? ? subject : certificate_name.name : csr.common_name)
    DomainControlValidation.email_address_choices(name)
  end

  def self.email_address_choices(name)
    name=CertificateContent.non_wildcard_name(name)
    Rails.cache.fetch("email_address_choices/#{name}", expires_in: EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days) do
      return [] unless DomainNameValidator.valid?(name,false)
      d=::PublicSuffix.parse(name.downcase)
      subdomains = d.trd ? d.trd.split(".") : []
      subdomains.shift if subdomains[0]=="*" #remove wildcard
      [].tap {|s|
        0.upto(subdomains.count) do |i|
          if i==0
            s << d.domain
          else
            s << (subdomains.slice(-i,subdomains.count)<<d.domain).join(".")
          end
        end
      }.map do |e|
        AUTHORITY_EMAIL_ADDRESSES.map do |ae|
          ae+e
        end
      end.flatten
    end
  end

  def self.approved_email_address?(choices, selection)
    choices.include? selection
  end

  def comodo_email_address_choices
    write_attribute(:candidate_addresses, ComodoApi.domain_control_email_choices(certificate_name.name).email_address_choices)
    save(validate: false)
  end

  def candidate_addresses
    if read_attribute(:candidate_addresses).blank?
      # delay.comodo_email_address_choices
      email_address_choices
    else
      read_attribute(:candidate_addresses)
    end
  end

  def friendly_action

  end

  def action_performed
    "#{method_for_api({http_csr_hash: "scanning for #{certificate_name.dcv_url}",
                       https_csr_hash: "scanning for #{certificate_name.dcv_url}",
                       cname_csr_hash: "scanning for CNAME: #{certificate_name.cname_origin} -> #{certificate_name.cname_destination}",
                       email: "sent validation to #{self.email_address}"})}"
  end

  def self.icann_contacts
    # txt = <https://www.icann.org/registrar-reports/accreditation-qualified-list.html>
    # txt.scan(/Email: (.*?)\n/).flatten.uniq
    ["customerservice@networksolutions.com",
        "registrarmail@plisk.com",
        "info@007names.com",
        "contact@0101domain.com",
        "compliance@ionos.de",
        "sales@101domain.com",
        "adm.dom@cdmon.com",
        "services@123-reg.co.uk",
        "support@mydomain-inc.com",
        "info@1api.net",
        "service@22.cn",
        "amcadory@aahwed.wed",
        "registry@nameisp.com",
        "info@itconnect.se",
        "icann@abansysandhostytec.com",
        "service@aboss.com",
        "hostmaster@above.com",
        "mlattouf@agip.com",
        "andrei@acwebconnecting.com",
        "support@namebright.com",
        "dominios@acens.com",
        "icanncompliance@ait.com",
        "public@aerotek.com.tr",
        "accounting@dnsimple.com",
        "legal@afproxy.africa",
        "corporate@afriregister.com",
        "agrinoon@agrinoon.com",
        "registrar-abuse@akamai.com",
        "destek@alantron.com",
        "president@alfena.com",
        "regsupport@list.alibaba-inc.com",
        "coo@alibrother-inc.com",
        "support@alices-registry.com",
        "vruiz@herrero.es",
        "registrar@alpinedomains.com",
        "registrar@amazon.com",
        "icann@buydomains.com",
        "tldadmin@logicboxes.com",
        "info@vebonix.com",
        "admin@maprilis.net",
        "support@heberjahiz.com",
        "paul.andersen@arcticnames.com",
        "support@melbourneit.com.au",
        "domainnames@arsys.es",
        "priority@staff.aruba.it",
        "nicrelations@ascio.com",
        "support@asiaregister.com",
        "byazici@atakteknoloji.com",
        "chams@ati.tn",
        "info@authenticweb.com",
        "help@wordpress.com",
        "xiaoyan@moas.com",
        "luca.barbero@barbero.co.uk",
        "bob@nominate.net",
        "icann@prodomaines.com",
        "support@beget.com",
        "wanmiantao01@baidu.com",
        "registrar@brandma.co",
        "overseas@guoxuwang.cn",
        "xulu@rntd.cn",
        "abuse@dns.com.cn",
        "hougang@jingkewang.net",
        "zjbzj@iwanshang.com",
        "zhangshuang@sfn.cn",
        "kun@namemax.cn",
        "yu@zhongwannet.cn",
        "info@zhuoyue.wang",
        "wangdi@zihai24.com",
        "registry@binero.se",
        "contact@bizcn.com",
        "sales@blacknight.com",
        "support@bluerazor.com",
        "legal@bomboraregistrar.com",
        "sands@aplegal.com",
        "robert.rolls@domaincentral.com.au",
        "billing@brdomain.jp",
        "dpatel@namejuice.com",
        "contact@brandsight.com",
        "info@brennercom.com",
        "info@brandregistrarsolutions.com",
        "icann@bw.ae",
        "brian.conchuratt@corsearch.com",
        "support@001.ca",
        "bcrull@webhero.com",
        "admin@ccireg.com",
        "info@ukrnames.com",
        "admin@cheap-domains-registration.com",
        "public-hk@51web.com",
        "unclemoon@hotmail.com",
        "abuse@west.cn",
        "domain@chinanet.cc",
        "shenghai@cht.com.tw",
        "demi@diymysite.com",
        "registrar-public@cloudflare.com",
        "contact@ordertld.com",
        "icann@galcomm.com",
        "support@corehub.net",
        "tldsupport@cscinfo.com",
        "tldsupport@cscglobal.com",
        "domain@cosmotown.com",
        "en.complaint@cps-datensysteme.de",
        "registrar-admin@cronon.net",
        "icann@nrw.net",
        "hostmaster@magic.fr",
        "info@resellercamp.com",
        "registrar@rumahweb.co.id",
        "registrar@dotmedia.com",
        "domain@dainippon.co.jp",
        "invoice@danesconames.com",
        "dominios@donweb.com",
        "icanncompliancesupport@deluxe.com",
        "general@demys.com",
        "info.domainregistrar@telekom.de",
        "pc@domains.co.za",
        "support@digitalcandy.com",
        "volkan.oransoy@digivity.com",
        "icann@dinahosting.com",
        "registrar@directnic.com",
        "info@dns.business",
        "wythewang@tencent.com",
        "icann@tldfuture.com",
        "macsen@namespace.com",
        "icann@tldomain.cn",
        "adam@idealhosting.com",
        "domainjamboree1@gmail.com",
        "service@ename.com",
        "cs@domainoriental.com",
        "support@dotearth.com",
        "registries@domainr.com",
        "support@dtnt.com",
        "info@domaintrain.com",
        "angus@domainvault.kiwi",
        "administrator@domainit.com",
        "support@domain-inc.net",
        "legal@domainallies.com",
        "support@domainbox.com",
        "gchetcuti@domainclip.com",
        "rafi@domainclub.com",
        "support@domaincontext.com",
        "contact@domainia.com",
        "support@domainmonster.com",
        "support@domainname.com",
        "info@domainoo.com",
        "support@domainpeople.com",
        "erlich@domainregistryinc.com",
        "violetta@domains.coop",
        "daniel@domainsbot.com",
        "support@name.com",
        "support@domainnameshop.com",
        "jim.schrand@dominion.domains",
        "alexandra.fa@domraider.com",
        "domreg@registrar.libris.com",
        "support@mail.domus-llc.com",
        "inquiries@dotology.com",
        "helen@dotalliance.com",
        "info@dotarai.co.th",
        "domain@dotnamekorea.com",
        "zsolt.komaromi@dotroll.com",
        "contact@radixregistry.com",
        "legal@dreamhost.com",
        "info@dynadot.com",
        "info@dynadot0.com",
        "info@dynadot1.com",
        "info@dynadot10.com",
        "info@dynadot11.com",
        "info@dynadot12.com",
        "info@dynadot13.com",
        "info@dynadot14.com",
        "info@dynadot15.com",
        "info@dynadot16.com",
        "info@dynadot17.com",
        "info@dynadot2.com",
        "info@dynadot3.com",
        "info@dynadot4.com",
        "info@dynadot5.com",
        "info@dynadot6.com",
        "info@dynadot7.com",
        "info@dynadot8.com",
        "info@dynadot9.com",
        "maneesh@eastnames.com",
        "support@easydns.com",
        "hostmaster@easyspace.com",
        "info@ebrandservices.com",
        "admin@ednitsoft.com",
        "info@edomains.com",
        "serven@eims.cn",
        "service@domain.cn",
        "service@ejee.com",
        "info@ekados.com",
        "registrar@nic.ae",
        "info@papaki.gr",
        "support@encirca.com",
        "legal@enom.com",
        "nic@entorno.es",
        "compliance@epag.de",
        "rob@epik.com",
        "info@todaynic.com",
        "guanxiaojun@easeu.net",
        "icann@eurodns.com",
        "domain_admin-sl-ww@wwpdl.vnet.ibm.com",
        "f.khan@experinom.net",
        "legal@fastdomain.com",
        "kadriye.daginik@isimtescil.net",
        "registrar@fiducia.com",
        "domains.info@netclues.com",
        "support@appdetex.com",
        "domain@72e.net",
        "compliance@freeparking.co.uk",
        "support@domaine.fr",
        "18662827@qq.com",
        "nican@domainprocessor.com",
        "zx@guoxuwang.cn",
        "rrinfo@gabia.com",
        "stephan.ramoin@gandi.net",
        "h.aboulfeth@genious.net",
        "marije@gesloten.cw",
        "quaynor@ghana.com",
        "paul@gkg.net",
        "cs@gdntcl.com",
        "public.contact@website.ws",
        "hostmaster@global-village.de",
        "domain.master@brights.jp",
        "icann@gmo.jp",
        "gmo-di@gmo.jp",
        "info@tenten.vn",
        "icann@goaustraliadomains.com",
        "icann@gocanadadomains.com",
        "icann@gochinadomains.com",
        "icann@gofrancedomains.com",
        "icann@gomontenegrodomains.com",
        "legal@godaddy.com",
        "admin@gooddomainregistry.com",
        "registrar@google.com",
        "info@subreg.cz",
        "soporte@loading.es",
        "registrarhuyi@huyi.cn",
        "chenlq@gzidc.com",
        "admin@nicenic.net",
        "reg@gz.com",
        "bizsupport@qq.com",
        "qiping@easeu.net",
        "legal@hainanuniveral.com",
        "doregi@doregi.com",
        "support@17ex.com",
        "service@registrar.eb.com.cn",
        "zhangkai@marksmile.com",
        "flora@goldenname.com",
        "info@haveaname.com",
        "public@juming.com",
        "admin@hellodotnyc.com",
        "icann@cndns.cn",
        "info@hetzner.com",
        "lugaoming@cnhlj.cn",
        "hoapdicompany@gmail.com",
        "rapublic@hoganlovells.com",
        "admin@dns.com",
        "755792791@qq.com",
        "info@host.it",
        "laurent@hosteur.com",
        "sales@openprovider.com",
        "icann@ukraine.com.ua",
        "domains@hostinger.com",
        "helpdesk@hostnet.nl",
        "nic@hostpoint.ch",
        "info@http.net",
        "cherrie.chong@8hy.hk",
        "gtld-admin@do-reg.jp",
        "icann@ihs.com.tr",
        "registry@ilait.se",
        "reg@imperialregistrations.com",
        "registrar@in2net.com",
        "ry-admin1@i-names.co.kr",
        "registrar@inet.vn",
        "support@infomaniak.com",
        "icann@123domain.eu",
        "beat.fehr@inic.ch",
        "registrar@innovadeus.com",
        "accredit@instantnames.com",
        "registry_admin@instra.com",
        "icann@interdominios.com",
        "support@gonbei.jp",
        "fengshuo@zdns.cn",
        "info@support.internet.bs",
        "pb@imena.ua",
        "wu@iwo.com",
        "b.barakov@intracomme.com",
        "info@inwx.com",
        "info@iptwins.com",
        "gtld-contact@jprs.co.jp",
        "idc@55hl.com",
        "contact@jprs-registrar.co.jp",
        "domain@kagoya.ad.jp",
        "hostmaster@domains.lt",
        "info@key-systems.net",
        "kheweul@kheweul.com",
        "policy@knetreg.cn",
        "registrar@knipp.de",
        "icann@kontent.com",
        "domain@ksidc.net",
        "zeu@cocen.com",
        "info@kuwaitnet.net",
        "domains-registrar@corsearch.com",
        "support@larsendata.com",
        "support@hostgator.com",
        "registry-support@lcn.com",
        "office@domaintechnik.at",
        "icann@lemarit.com",
        "domains@lexsynergy.com",
        "domaine@lws.fr",
        "domains@propersupport.com",
        "machev@mainreg.com",
        "icannbiz@qy.cn",
        "domains@marcaria.com",
        "compliance@markmonitor.com",
        "icann@matbao.com",
        "pang@laws.ms",
        "billing@registermatrix.com",
        "ms.lee@hosting.kr",
        "support@metaregistrar.com",
        "domain@mfro.net",
        "colequin@microsoft.com",
        "info@mijninternetoplossing.nl",
        "ops@mmx.co",
        "support@misk.com",
        "accredit@misternic.com",
        "info@moniker.com",
        "rkumar@viseshinfo.com",
        "domain@nakazawa-trading.co.jp",
        "support@nameshare.com",
        "cai@name.cc",
        "contact@namebay.com",
        "help@yay.com",
        "support@namecheap.com",
        "support@namepal.com",
        "legal@namescout.com",
        "registrar@nameshield.net",
        "support@namesilo.com",
        "admin@namespro.ca",
        "info@nameweb.biz",
        "support@naugus.com",
        "jc.vignes@nccgroup.com",
        "icann-domain@neen.it",
        "info@mail.neonic.com",
        "adam@defty.com",
        "domainbilling@net4india.com",
        "foreign@net-chinese.com.tw",
        "info@netart-registrar.com",
        "jchen@dnsexit.com",
        "i-c-a-nn-p-u-b-l-ic@netearthone.com",
        "info@netestate.com",
        "sales@netim.com",
        "andrew.bennett@netistrar.com",
        "nicrelations@netnames.com.au",
        "icann@netowl.jp",
        "webmaster@ibi.net",
        "support@netregistry.com.au",
        "bensonoff@webmasters.com",
        "akkyicann@nic.mx",
        "servicedesk@netzadresse.at",
        "legal@netzone.ch",
        "gabriela@neubox.net",
        "accredit@neudomain.com",
        "hquan@nhanhoa.com.vn",
        "dl_registrar@nhn-japan.com",
        "support@nicco.com",
        "support@nicenic.net",
        "accredit@nicreg.com",
        "customerservice@nicproxy.com",
        "info@nictrade.se",
        "cf@houm.me",
        "admin@comlaude.com",
        "gestiontld@nominalia.com",
        "nrs@nominetregistrar.co.uk",
        "scott.jung@nordnet.fr",
        "registry@nordreg.se",
        "domain@no1host.com",
        "fromm@omnis.com",
        "hostmaster@one.com",
        "info@onlide.com",
        "icann@free.org",
        "icann@onlinenic.com",
        "registry_admin@onlydomains.com",
        "accredit@openname.com",
        "jzuurbier@opentld.com",
        "icann@dyn.com",
        "domaine-admin@orange.com",
        "service@ourdomains.com",
        "icann@ovh.net",
        "info@ownidentity.com",
        "support@ownregistrar.com",
        "pa@pavietnam.vn",
        "service@paimi.com",
        "support@pairdomains.com",
        "info@paknic.com",
        "info@paragonnames.com",
        "anand@domaintegrity.com",
        "tan@pheenix.com",
        "domains@support.planethoster.info",
        "info@porkbun.com",
        "anna.kronvall@portsgroup.com",
        "support@promopeople.com",
        "info@hostingireland.ie",
        "registry@psi-japan.co.jp",
        "hostmaster@psi-usa.info",
        "sales@resellerid.com",
        "info@biznetgio.com",
        "support@puritynames.com",
        "309709519@qq.com",
        "joseph@oxygen.nyc",
        "support@realtimeregister.com",
        "legal@rebel.com",
        "legal@rebel.ca",
        "info@reg2c.com",
        "tld-adm@nic.ru",
        "info@register.eu",
        "info.registrar@register.it",
        "support@register.ca",
        "support@register4less.com",
        "support@registrarmanager.com",
        "lienko@reg.ru",
        "tld-adm@r01.ru",
        "support@registrarsafe.com",
        "support@registrarsec.com",
        "support@registrationtek.com",
        "info@mastername.ru",
        "service@registrygate.com",
        "s.shar@regtime.net",
        "info@hoster.by",
        "support@resellserv.com",
        "info@rockenstein.de",
        "c.tine@safebrands.com",
        "hostmaster@safenames.net",
        "irina.volkova@salenames.ru",
        "domain@sds.co.kr",
        "registrar@fabulous.com",
        "secura@domainregistry.de",
        "legal@sedo.com",
        "domini@serverplan.com",
        "technical_cn@163.com",
        "domains@phxcapital.com",
        "icann@huaimi.com",
        "ken@oray.com",
        "tld@cndns.com",
        "heyingdan@ucloud.cn",
        "domain@yovole.com",
        "public@esin.com.cn",
        "domain@idcicp.com",
        "zhaixiang708@163.com",
        "registrar@ilovewww.com",
        "support@sibername.com",
        "rick@sitematrix.com",
        "moshef@sitename.com",
        "domain@sksaweb.com",
        "domain@skyclear.co.jp",
        "contact@smallworldregistrar.com",
        "info@scip.es",
        "registrar@squarespace.com",
        "info@rolr.eu",
        "admin@storkregistry.com",
        "phuongnguyen@superdata.vn",
        "rarlegal@pool.com",
        "dominios@serveisweb.com",
        "helpdesk@switchplus.ch",
        "sales@synergywholesale.com",
        "publiccontact@twnic.net.tw",
        "radar.icann.org@icann.takaenterprise.com",
        "icann@tecnocratica.net",
        "icann@2imagen.net",
        "saraswang@tencent.com",
        "info@theregistrarcompany.com",
        "nate.delanoy@spiritcom.com",
        "zhuiri@cnkuai.cn",
        "support@tierra.net",
        "icann-web-site-2017@tigertech.net",
        "pradeep.s@tirupatidomains.in",
        "lydiapesa@peoplebrowsr.com",
        "admin@tldregistrarsolutions.com",
        "support@tname.com",
        "infoserver@toglodo.com",
        "ceo@tonglechina.com",
        "icann@tool-domains.com",
        "801@idcicp.com",
        "info@topsystem.com",
        "den@topvisor.com",
        "info@totalregistrations.com",
        "domains@tppwholesale.com.au",
        "support@transip.nl",
        "admin@tropicregistry.com",
        "help@opensrs.com",
        "staff@tuonomegroup.com",
        "support-internet@twt.it",
        "ipm@ubilibet.com",
        "domainmanagement@uk2group.com",
        "support@openhost.co.nz",
        "raradmin@uniregistry.com",
        "support@united-domains.de",
        "icann@upperlink.ng",
        "support@pananames.com",
        "info@variomedia.de",
        "registries@antagus.de",
        "sales@ventraip.com.au",
        "billing@verelink.com",
        "viaweb0900@gmail.com",
        "service@vipinternet.com",
        "domains@no-ip.com",
        "registrar-admin@vividdomains.com",
        "domain.admin@vodien.com",
        "contact@wjbrands.com",
        "support@webnic.cc",
        "compliance@zenregistry.com",
        "sales@web4africa.net",
        "general-icann@webagentur.at",
        "icann-contact@webair.com",
        "info@webnames.ru",
        "president@webnames.ca",
        "lillian@hkdns.hk",
        "support@wildwestdomains.com",
        "domain@wingnames.co.jp",
        "dominios@suempresa.com",
        "registrar@wix.com",
        "icann@wixi.jp",
        "rwolfe@wolfedomain.com",
        "csupport@worldbizdomains.com",
        "office@world4you.com",
        "xuweiyang@qianxinet.com",
        "icann@35.cn",
        "kf@zzy.cn",
        "chen@nawang.cn",
        "huanghongxia@micang.com",
        "xingqiu@xmisp.com",
        "domain@yuwang.com",
        "contact@zhong.top",
        "support@xinnet.com",
        "kefu@reg.cn",
        "reg@reg.cn",
        "public@861.cn",
        "382658@qq.com",
        "info@zuuq.com",
        "mike@humb.ly",
        "pr@zohodomains.com",
        "registrar3814@brnamd.co"]
  end

end
