module Concerns
  module CertificateContent
    extend ActiveSupport::Concern

    included do
      SIGNING_REQUEST_REGEX = %r{\A[\w\-/\s\n\+=]+\Z}.freeze

      # thought would be 2048, be see http://groups.google.com/group/mozilla.dev.security.policy/browse_thread/thread/7ceb6dd787e20da3# for details
      MIN_KEY_SIZE = [2048, 3072, 4096, 6144, 8192].freeze
      NOT_VALID_ISO_CODE = 'is not a valid 2 lettered ISO-3166 country code.'

      ADMINISTRATIVE_ROLE = 'administrative'
      CONTACT_ROLES = %w[administrative billing technical validation]

      RESELLER_FIELDS_TO_COPY = %w[first_name last_name po_box address1 address2 address3 city state postal_code email phone ext fax].freeze

      # terms in this list that are submitted as domains for an ssl will be kicked back
      BARRED_SSL_TERMS = %w[\A\. \.onion\z \.local\z].freeze

      TRADEMARKS = %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.google\.com\z \Agoogle\.com\z .*?\.whatsapp\.com\z \Awhatsapp\.com\z
                      .*?\.?facebook\.com \Afacebook\.com\z
                      .*?\.apple\.com\z \Aapple\.com\z .*?\.microsoft\.com\z \Amicrosoft\.com\z .*?\.paypal\.com\z \Apaypal\.com\z
                      .*?\.mozilla\.com\z \Amozilla\.com\z .*?\.gmail\.com\z \Agmail\.com\z .*?\.goog\.com\z \Agoog\.com\z
                      .*?\.?github\.com .*?\.?amazon\.com .*?\.?cloudapp\.com amzn ssltools certchat .*?\.certlock\.com\z \Acertlock\.com\z
                      .*?\.10million\.org .*?\.android\.com\z \Aandroid\.com\z .*?\.aol\.com .*?\.azadegi\.com .*?\.balatarin\.com .*?\.?comodo\.com
                      .*?\.?digicert\.com .*?\.?yahoo\.com .*?\.?entrust\.com .*?\.?godaddy\.com .*?\.oracle\.com\z \Aoracle\.com\z
                      .*?\.?globalsign\.com .*?\.JanamFadayeRahbar\.com .*?\.?logmein\.com .*?\.mossad\.gov\.il
                      .*?\.?mozilla\.org .*?\.RamzShekaneBozorg\.com .*?\.SahebeDonyayeDigital\.com .*?\.skype\.com .*?\.startssl\.com
                      .*?\.?thawte\.com .*?\.torproject\.org .*?\.walla\.co\.il .*?\.windowsupdate\.com .*?\.wordpress\.com addons\.mozilla\.org
                      azadegi\.com Comodo\sRoot\sCA CyberTrust\sRoot\sCA DigiCert\sRoot\sCA Equifax\sRoot\sCA friends\.walla\.co\.il
                      GlobalSign\sRoot\sCA login\.live\.com my\.screenname\.aol\.com secure\.logmein\.com
                      Thawte\sRoot\sCA twitter\.com VeriSign\sRoot\sCA wordpress\.com www\.10million\.org www\.balatarin\.com
                      cia\.gov \.cybertrust\.com equifax\.com hamdami\.com mossad\.gov\.il sis\.gov\.uk
                      yahoo\.com login\.skype\.com mozilla\.org \.live\.com global\strustee].freeze

      WHITELIST = { 492_127 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    491_981 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    # temporary for sandbox
                    474_187 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    493_588 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    # Nick (next 3)
                    492_759 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    497_080 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    474_299 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    477_317 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z],
                    464_808 => %w[.*?\.ssl\.com\z \Assl\.com\z .*?\.certlock\.com\z \Acertlock\.com\z] }.freeze

      DOMAIN_COUNT_OFFLOAD = 50

      # SSL.com=>Comodo
      COMODO_SERVER_SOFTWARE_MAPPINGS = {
        1 => -1, 2 => 1, 3 => 2, 4 => 3, 5 => 4, 6 => 33, 7 => 34, 8 => 5,
        9 => 6, 10 => 29, 11 => 32, 12 => 7, 13 => 8, 14 => 9, 15 => 10,
        16 => 11, 17 => 12, 18 => 13, 19 => 14, 20 => 35, 21 => 15,
        22 => 16, 23 => 17, 24 => 18, 25 => 30, 26 => 19, 27 => 20, 28 => 21,
        29 => 22, 30 => 23, 31 => 24, 32 => 25, 33 => 26, 34 => 27, 35 => 31, 36 => 28, 37 => -1, 38 => -1, 39 => 3
      }.freeze

      INTRANET_IP_REGEX = /\A(127\.0\.0\.1)|(10.\d{,3}.\d{,3}.\d{,3})|(172\.1[6-9].\d{,3}.\d{,3})|(172\.2[0-9].\d{,3}.\d{,3})|(172\.3[0-1].\d{,3}.\d{,3})|(192\.168.\d{,3}.\d{,3})\z/.freeze

      # dtnt comodo chained is 492703
      # Hikma is 204730
      # 499740 using Azure. Remove once we are in Azure
      COMODO_SSL_ACCOUNTS = [467564, 16077, 204730, 492703, 21291, 499740, 490782]
    end
  end
end
