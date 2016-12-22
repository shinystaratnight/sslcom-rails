FactoryGirl.define do
  factory :certificate do
    status       'live'
    published_as 'live'
    roles        'Registered'

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
      display_order         {{all: 1, index: 1}}
      description           {{certificate_type: "Basic SSL",
                              points:           "<div class='check'>quick domain validation</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$10,000 USD insurance guaranty</div>\n                               <div class='check'>activates SSL Secure Site Seal</div>\n                               <div class='check'>2048 bit public key encryption</div>\n                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n                               <div class='check'>quick issuance</div>\n                               <div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>",
                              validation_level: "domain",
                              summary:          "for securing small sites",
                              abbr:             "Basic SSL"
                            }}

      after(:create) do |certificate|
        value = 730
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
            amount:                   "#{value*10.7}",
            display_order:            n,
            item_type:                'duration',
            value:                    value,
            serial:                   "sslcombasic256ssl#{n}yr",
            published_as:             "live",
          )
          value += 366
        end
      end
    end

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
                            }}
    end

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
      display_order         {{all: 1, index: 1}}
      description           {{certificate_type: "High Assurance UCC",
                              points:           "<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n",
                              validation_level: "Class 2 DoD",
                              summary:          "for Exchange and Communications Server\n",
                              abbr:             "UCC SSL"
                            }}
    end

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
                            }}
    end
  end
end
