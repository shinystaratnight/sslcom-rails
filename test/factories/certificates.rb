FactoryGirl.define do
  factory :certificate do
    status       'live'
    published_as 'live'
    roles        'Registered'
    
    # Basic SSL (basic256sslcom)
    # ==========================================================================
    trait :basicssl do
      reseller_tier_id      nil
      title                 'Basic SSL'
      summary               nil
      text_only_summary     nil
      text_only_description nil
      allow_wildcard_ucc    nil
      serial                'basic256sslcom'
      product               'basicssl'
      icons                 {{main: 'silver_lock_lg.gif'}}
      display_order         {{all: 3, index: 2}}
      description           {{certificate_type: "Basic SSL",
                              points:           "<div class='check'>quick domain validation</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$10,000 USD insurance guaranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>",
                              validation_level: "domain",
                              summary:          "for securing small sites",
                              abbr:             "Basic SSL"
                            }.with_indifferent_access}

      after(:create) do |certificate|
        value = 730
        group_duration = certificate.product_variant_groups.create(
          title:                 'Duration',
          status:                'live',
          description:           'Duration',
          text_only_description: 'Duration',
          display_order:          1,
          serial:                 nil,
          published_as:           'live',
        )
        
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title:                    "#{n} Years",
            status:                   "live",
            description:              "#{n} years",
            text_only_description:    "#{n} years",
            amount:                   value*10.7,
            display_order:            n,
            item_type:                'duration',
            value:                    value,
            serial:                   "sslcombasic256ssl#{n}yr",
            published_as:             "live",
          )
          value += 365
        end
      end
    end

    # EV SSL (ev256sslcom)
    # ==========================================================================
    trait :evssl do
      reseller_tier_id      nil
      title                 'Enterprise EV SSL'
      summary               nil
      text_only_summary     nil
      text_only_description nil
      allow_wildcard_ucc    nil
      serial                'ev256sslcom'
      product               'ev'
      icons                 {{main: 'ev_bar_lg.jpg'}}
      display_order         {{all: 1, index: 1}}
      description           {{certificate_type: "Enterprise EV",
                              points:           "<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guaranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div> \n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n",
                              validation_level: "Class 3 DoD",
                              summary:          "highest trust assurance",
                              abbr:             "EV SSL"
                            }.with_indifferent_access}
                              
      after(:create) do |certificate|
        value = 365
        group_duration = certificate.product_variant_groups.create(
          title:                 'Duration',
          status:                'live',
          description:           'Duration',
          text_only_description: 'Duration',
          display_order:          1,
          serial:                 nil,
          published_as:           'live',
        )
        (1..2).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title:                    "#{n} Years",
            status:                   "live",
            description:              "#{n} years",
            text_only_description:    "#{n} years",
            amount:                   value*10.7,
            display_order:            n,
            item_type:                'duration',
            value:                    value,
            serial:                   "sslcomev256ssl#{n}yr",
            published_as:             "live",
          )
          value += 365
        end
        
      end  
    end
    
    # UCC SSL (ucc256sslcom)
    # ==========================================================================
    trait :uccssl do
      reseller_tier_id      nil
      title                 'Multi-domain UCC SSL'
      summary               nil
      text_only_summary     nil
      text_only_description nil
      allow_wildcard_ucc    nil
      serial                'ucc256sslcom'
      product               'ucc'
      icons                 {{main: 'silver_locks_lg.gif'}}
      display_order         {{all: 6, index: 6}}
      description           {{certificate_type: "High Assurance UCC",
                              points:           "<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n",
                              validation_level: "Class 2 DoD",
                              summary:          "for Exchange and Communications Server\n",
                              abbr:             "UCC SSL"
                            }.with_indifferent_access}
      after(:create) do |certificate|
        # Server License
        value  = 365
        group_server = certificate.product_variant_groups.create(
          title:                 'Server Licenses',
          status:                'live',
          description:           'Server Licenses',
          text_only_description: 'Server Licenses',
          display_order:          3,
          serial:                 nil,
          published_as:           'live',
        )
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_server.id,
            title:                 "#{n} Year Additional Server License",
            status:                "live",
            description:           "#{n} year additional server license",
            text_only_description: "#{n} year additional server license",
            amount:                value*10.7,
            display_order:         n,
            item_type:             'server_license',
            value:                 value,
            serial:                "sslcomucc256ssl#{n}yrsl",
            published_as:          "live",
          )
          value  += 365
        end
        # Domain
        group_domain = certificate.product_variant_groups.create(
          title:                 'Domains',
          status:                'live',
          description:           'Domain Names',
          text_only_description: 'Domain Names',
          display_order:          2,
          serial:                 nil,
          published_as:           'live',
        )
        # For 3 Domains
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title:                    "#{n} Year Domain For 3 Domains (ea domain)",
            status:                   "live",
            description:              "#{n} year domain for 3 domains (ea domain)",
            text_only_description:    "#{n} year domain for 3 domains (ea domain)",
            amount:                   value*10.7,
            display_order:            n,
            item_type:                'ucc_domain',
            value:                    value,
            serial:                   "sslcomucc256ssl#{n}yrdm",
            published_as:             "live",
          )
          value += 365
        end
        # For additional domains above max of 3
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title:                    "#{n} Year Domain For Domains 4-2000 (ea domain)",
            status:                   "live",
            description:              "#{n} Year Domain For Domains 4-2000 (ea domain)",
            text_only_description:    "#{n} Year Domain For Domains 4-2000 (ea domain)",
            amount:                   value*6,
            display_order:            n,
            item_type:                'ucc_domain',
            value:                    value,
            serial:                   "sslcomucc256ssl#{n}yradm",
            published_as:             "live",
          )
          value += 365
        end
        # For wildcard domains
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title:                    "#{n} Year Wildcard Domain",
            status:                   "live",
            description:              "#{n} Year Wildcard Domain",
            text_only_description:    "#{n} Year Wildcard Domain",
            amount:                   value*14,
            display_order:            n,
            item_type:                'ucc_domain',
            value:                    value,
            serial:                   "sslcomucc256ssl#{n}yrwcdm",
            published_as:             "live",
          )
          value += 365
        end
      end
    end
    
    # Wildcard SSL (wc256sslcom)
    # ==========================================================================
    trait :wcssl do
      reseller_tier_id      nil
      title                 'Multi-subdomain Wildcard SSL'
      summary               nil
      text_only_summary     nil
      text_only_description nil
      allow_wildcard_ucc    nil
      serial                'wc256sslcom'
      product               'wildcard'
      icons                 {{main: 'gold_locks_lg.gif'}}
      display_order         {{all: 1, index: 1}}
      description           {{certificate_type: "Wildcard",
                              points:           "<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>unlimited subdomains</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n",
                              validation_level: "Class 2 DoD",
                              summary:          "high validation and trust value",
                              abbr:             "Wildcard SSL"
                            }.with_indifferent_access}

      after(:create) do |certificate|
        value  = 365
        group_server = certificate.product_variant_groups.create(
          title:                 'Server Licenses',
          status:                'live',
          description:           'Server Licenses',
          text_only_description: 'Server Licenses',
          display_order:          2,
          serial:                 nil,
          published_as:           'live',
        )
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_server.id,
            title:                 "#{n} Year Additional Server License",
            status:                "live",
            description:           "#{n} year additional server license",
            text_only_description: "#{n} year additional server license",
            amount:                value*10.7,
            display_order:         n,
            item_type:             'server_license',
            value:                 value,
            serial:                "sslcomwc256ssl#{n}yrsl",
            published_as:          "live",
          )
          value  += 365
        end
        value = 365
        group_duration = certificate.product_variant_groups.create(
          title:                 'Duration',
          status:                'live',
          description:           'Duration',
          text_only_description: 'Duration',
          display_order:          1,
          serial:                 nil,
          published_as:           'live',
        )
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title:                    "#{n} Years",
            status:                   "live",
            description:              "#{n} years",
            text_only_description:    "#{n} years",
            amount:                   value*10.7,
            display_order:            n,
            item_type:                'duration',
            value:                    value,
            serial:                   "sslcomwc256ssl#{n}yr",
            published_as:             "live",
          )
          value += 365
        end
      end
    end
    
    # High Assurance SSL (ov256sslcom)
    # ==========================================================================
    trait :ovssl do
      reseller_tier_id      nil
      title                 'High Assurance SSL'
      summary               nil
      text_only_summary     nil
      text_only_description nil
      allow_wildcard_ucc    nil
      serial                'ov256sslcom'
      product               'high_assurance'
      icons                 {{main: 'gold_lock_lg.gif'}}
      display_order         {{all: 3, index: 2}}
      description           {{certificate_type: "High Assurance",
                              points:            "<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n",
                              validation_level: "Class 2 DoD",
                              summary:          "standard ssl\n",
                              abbr:             "High Assurance SSL"
                            }.with_indifferent_access}

      after(:create) do |certificate|
        value = 365
        group = certificate.product_variant_groups.create(
          title:                 'Duration',
          status:                'live',
          description:           'Duration',
          text_only_description: 'Duration',
          display_order:          1,
          serial:                 nil,
          published_as:           'live',
        )
        
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group.id,
            title:                    "#{n} Years",
            status:                   "live",
            description:              "#{n} years",
            text_only_description:    "#{n} years",
            amount:                   value*10.7,
            display_order:            n,
            item_type:                'duration',
            value:                    value,
            serial:                   "sslcomov256ssl#{n}yr",
            published_as:             "live",
          )
          value += 365
        end
      end
    end
    
    # Premium SSL (premium256sslcom)
    # ==========================================================================
    trait :premiumssl do
      reseller_tier_id      nil
      title                 'Premium Multi-subdomain SSL'
      summary               nil
      text_only_summary     nil
      text_only_description nil
      allow_wildcard_ucc    nil
      serial                'premium256sslcom'
      product               'premiumssl'
      icons                 {{main: 'silver_locks_lg.gif'}}
      display_order         {{all: 6, index: 6}}
      description           {{certificate_type: "Premium SSL",
                              points:           "<div class='check'>quick domain validation</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$10,000 USD insurance guaranty</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n",
                              validation_level: "domain",
                              summary:          "ssl for up to 3 subdomains\n",
                              abbr:             "Premium SSL"
                            }.with_indifferent_access}
      
      after(:create) do |certificate|
        # Domain
        group_domain = certificate.product_variant_groups.create(
          title:                 'Domains',
          status:                'live',
          description:           'Domain Names',
          text_only_description: 'Domain Names',
          display_order:         2,
          serial:                nil,
          published_as:          'live',
        )
        # For 3 Domains
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title:                    "#{n} Year Domain For 3 Domains (ea domain)",
            status:                   "live",
            description:              "#{n} year domain for 3 domains (ea domain)",
            text_only_description:    "#{n} year domain for 3 domains (ea domain)",
            amount:                   value*10.7,
            display_order:            n,
            item_type:                'ucc_domain',
            value:                    value,
            serial:                   "sslcompremium256ssl#{n}yrdm",
            published_as:             "live",
          )
          value += 365
        end
        # For Domains 4-200
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title:                    "#{n} Year Domain For Domains 4-200 (ea domain)",
            status:                   "live",
            description:              "#{n} Year Domain For Domains 4-200 (ea domain)",
            text_only_description:    "#{n} Year Domain For Domains 4-200 (ea domain)",
            amount:                   value*10.7,
            display_order:            n,
            item_type:                'ucc_domain',
            value:                    value,
            serial:                   "sslcompremium256ssl#{n}yradm",
            published_as:             "live",
          )
          value += 365
        end
      end
    end
  end
end
