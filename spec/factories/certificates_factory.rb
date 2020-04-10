# frozen_string_literal: true

# == Schema Information
#
# Table name: certificates
#
#  id                    :integer          not null, primary key
#  allow_wildcard_ucc    :boolean
#  description           :text(65535)
#  display_order         :string(255)
#  icons                 :string(255)
#  product               :string(255)
#  published_as          :string(16)       default("draft")
#  roles                 :string(255)      default("--- []")
#  serial                :string(255)
#  special_fields        :string(255)      default("--- []")
#  status                :string(255)
#  summary               :text(65535)
#  text_only_description :text(65535)
#  text_only_summary     :text(65535)
#  title                 :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  reseller_tier_id      :integer
#
# Indexes
#
#  index_certificates_on_reseller_tier_id  (reseller_tier_id)
#

FactoryBot.define do
  factory :certificate do
    status       { 'live' }
    published_as { 'live' }
    roles        { 'Registered' }

    transient do
      true_build { false }
    end

    factory :certificate_with_certificate_order do
      title                 { 'Enterprise EV Multi-domain UCC SSL' }
      allow_wildcard_ucc    { false }
      serial                { 'evucc256sslcom' }
      product               { 'evucc' }
      icons                 { { main: 'ev_bar_lg.jpg' } }
      display_order         { { all: 2, index: 5 } }
      description           do
        { certificate_type: 'Enterprise EV UCC',
          points: "<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n",
          validation_level: 'Class 3 DoD',
          summary: "for Exchange and Communications Server\n",
          abbr: 'EV UCC SSL' }.with_indifferent_access
      end
      # Note: Mocking should be explored for complicated associations
      after(:build) do |cert, options|
        unless options.true_build
          cert.save
          cert.product_variant_groups << create(:product_variant_group)
          product_variant_group = cert.product_variant_groups.first
          product_variant_group.product_variant_items << create(:product_variant_item, product_variant_group_id: product_variant_group.id)
          product_variant_item = product_variant_group.product_variant_items.first
          product_variant_item.sub_order_item = create(:sub_order_item, product_variant_item_id: product_variant_item.id)
          cert.save
        end
      end
    end

    # 100 Enterprise EV UCC/SAN SSL (evucc256sslcom)
    # ==========================================================================
    trait :evuccssl do
      title                 { 'Enterprise EV Multi-domain UCC SSL' }
      allow_wildcard_ucc    { false }
      serial                { 'evucc256sslcom' }
      product               { 'evucc' }
      icons                 { { main: 'ev_bar_lg.jpg' } }
      display_order         { { all: 2, index: 5 } }
      description           do
        { certificate_type: 'Enterprise EV UCC',
          points: "<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n",
          validation_level: 'Class 3 DoD',
          summary: "for Exchange and Communications Server\n",
          abbr: 'EV UCC SSL' }.with_indifferent_access
      end

      after(:create) do |certificate|
        # Domains
        value = 365
        amount = 13_300
        group_duration = certificate.product_variant_groups.create(
          title: 'Domains',
          status: 'live',
          description: 'Domain Names',
          text_only_description: 'Domain Names',
          display_order: 2,
          serial: nil,
          published_as: 'live'
        )
        (1..2).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title: "#{n} Year Domain For 3 Domains (ea domain)",
            status: 'live',
            description: "#{n} year domain for 3 domains (ea domain)",
            text_only_description: "#{n} year domain for 3 domains (ea domain)",
            amount: (n == 1 ? amount : amount * 1.6),
            display_order: n,
            item_type: 'ucc_domain',
            value: value,
            serial: "sslcomevucc256ssl#{n}yrdm",
            published_as: 'live'
          )
          value += 365
        end

        value = 365
        amount = 12_900
        (1..2).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title: "#{n} Year Domain For Domains 4-200 (ea domain)",
            status: 'live',
            description: "#{n} year domain for domains 4-200 (ea domain)",
            text_only_description: "#{n} year domain for domains 4-200 (ea domain)",
            amount: (n == 1 ? amount : amount * 1.6),
            display_order: n,
            item_type: 'ucc_domain',
            value: value,
            serial: "sslcomevucc256ssl#{n}yradm",
            published_as: 'live'
          )
          value += 365
        end

        # Server Licenses
        group_server = certificate.product_variant_groups.create(
          title: 'Server Licenses',
          status: 'live',
          description: 'Server Licenses',
          text_only_description: 'Server Licenses',
          display_order: 3,
          serial: nil,
          published_as: 'live'
        )

        value = 365
        amount = 1000
        (1..2).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_server.id,
            title: "#{n} Year Additional Server License",
            status: 'live',
            description: "#{n} year additional server license",
            text_only_description: "#{n} year additional server license",
            amount: (n == 1 ? amount : amount * 1.8),
            display_order: n,
            item_type: 'server_license',
            value: value,
            serial: "sslcomevucc256ssl#{n}yrsl",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # 106 Basic SSL (basic256sslcom)
    # ==========================================================================
    trait :basicssl do
      title                 { 'Basic SSL' }
      serial                { 'basic256sslcom' }
      product               { 'basicssl' }
      icons                 { { main: 'silver_lock_lg.gif' } }
      display_order         { { all: 3, index: 2 } }
      description           do
        { certificate_type: 'Basic SSL',
          points: "<div class='check'>quick domain validation</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$10,000 USD insurance guarranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>",
          validation_level: 'domain',
          summary: 'for securing small sites',
          abbr: 'Basic SSL' }.with_indifferent_access
      end

      after(:create) do |certificate|
        value = 730
        group_duration = certificate.product_variant_groups.create(
          title: 'Duration',
          status: 'live',
          description: 'Duration',
          text_only_description: 'Duration',
          display_order: 1,
          serial: nil,
          published_as: 'live'
        )

        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title: "#{n} Years",
            status: 'live',
            description: "#{n} years",
            text_only_description: "#{n} years",
            amount: value * 10.7,
            display_order: n,
            item_type: 'duration',
            value: value,
            serial: "sslcombasic256ssl#{n}yr",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # 102 EV SSL (ev256sslcom)
    # ==========================================================================
    trait :evssl do
      title                 { 'Enterprise EV SSL' }
      serial                { 'ev256sslcom' }
      product               { 'ev' }
      icons                 { { main: 'ev_bar_lg.jpg' } }
      display_order         { { all: 1, index: 1 } }
      description           do
        { certificate_type: 'Enterprise EV',
          points: "<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guarranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div> \n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n",
          validation_level: 'Class 3 DoD',
          summary: 'highest trust assurance',
          abbr: 'EV SSL' }.with_indifferent_access
      end

      after(:create) do |certificate|
        value = 365
        group_duration = certificate.product_variant_groups.create(
          title: 'Duration',
          status: 'live',
          description: 'Duration',
          text_only_description: 'Duration',
          display_order: 1,
          serial: nil,
          published_as: 'live'
        )
        (1..2).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title: "#{n} Years",
            status: 'live',
            description: "#{n} years",
            text_only_description: "#{n} years",
            amount: value * 10.7,
            display_order: n,
            item_type: 'duration',
            value: value,
            serial: "sslcomev256ssl#{n}yr",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # 101 UCC SSL (ucc256sslcom)
    # ==========================================================================
    trait :uccssl do
      title                 { 'Multi-domain UCC SSL' }
      serial                { 'ucc256sslcom' }
      product               { 'ucc' }
      icons                 { { main: 'silver_locks_lg.gif' } }
      display_order         { { all: 6, index: 6 } }
      description           do
        { certificate_type: 'High Assurance UCC',
          points: "<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n",
          validation_level: 'Class 2 DoD',
          summary: "for Exchange and Communications Server\n",
          abbr: 'UCC SSL' }.with_indifferent_access
      end
      after(:create) do |certificate|
        # Server License
        value = 365
        group_server = certificate.product_variant_groups.create(
          title: 'Server Licenses',
          status: 'live',
          description: 'Server Licenses',
          text_only_description: 'Server Licenses',
          display_order: 3,
          serial: nil,
          published_as: 'live'
        )
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_server.id,
            title: "#{n} Year Additional Server License",
            status: 'live',
            description: "#{n} year additional server license",
            text_only_description: "#{n} year additional server license",
            amount: value * 10.7,
            display_order: n,
            item_type: 'server_license',
            value: value,
            serial: "sslcomucc256ssl#{n}yrsl",
            published_as: 'live'
          )
          value += 365
        end
        # Domain
        group_domain = certificate.product_variant_groups.create(
          title: 'Domains',
          status: 'live',
          description: 'Domain Names',
          text_only_description: 'Domain Names',
          display_order: 2,
          serial: nil,
          published_as: 'live'
        )
        # For 3 Domains
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title: "#{n} Year Domain For 3 Domains (ea domain)",
            status: 'live',
            description: "#{n} year domain for 3 domains (ea domain)",
            text_only_description: "#{n} year domain for 3 domains (ea domain)",
            amount: value * 10.7,
            display_order: n,
            item_type: 'ucc_domain',
            value: value,
            serial: "sslcomucc256ssl#{n}yrdm",
            published_as: 'live'
          )
          value += 365
        end
        # For additional domains above max of 3
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title: "#{n} Year Domain For Domains 4-2000 (ea domain)",
            status: 'live',
            description: "#{n} Year Domain For Domains 4-2000 (ea domain)",
            text_only_description: "#{n} Year Domain For Domains 4-2000 (ea domain)",
            amount: value * 6,
            display_order: n,
            item_type: 'ucc_domain',
            value: value,
            serial: "sslcomucc256ssl#{n}yradm",
            published_as: 'live'
          )
          value += 365
        end
        # For wildcard domains
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title: "#{n} Year Wildcard Domain",
            status: 'live',
            description: "#{n} Year Wildcard Domain",
            text_only_description: "#{n} Year Wildcard Domain",
            amount: value * 14,
            display_order: n,
            item_type: 'ucc_domain',
            value: value,
            serial: "sslcomucc256ssl#{n}yrwcdm",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # Wildcard SSL (wc256sslcom)
    # ==========================================================================
    trait :wcssl do
      title                 { 'Multi-subdomain Wildcard SSL' }
      serial                { 'wc256sslcom' }
      product               { 'wildcard' }
      icons                 { { main: 'gold_locks_lg.gif' } }
      display_order         { { all: 1, index: 1 } }
      description           do
        { certificate_type: 'Wildcard',
          points: "<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>unlimited subdomains</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n",
          validation_level: 'Class 2 DoD',
          summary: 'high validation and trust value',
          abbr: 'Wildcard SSL' }.with_indifferent_access
      end

      after(:create) do |certificate|
        value = 365
        group_server = certificate.product_variant_groups.create(
          title: 'Server Licenses',
          status: 'live',
          description: 'Server Licenses',
          text_only_description: 'Server Licenses',
          display_order: 2,
          serial: nil,
          published_as: 'live'
        )
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_server.id,
            title: "#{n} Year Additional Server License",
            status: 'live',
            description: "#{n} year additional server license",
            text_only_description: "#{n} year additional server license",
            amount: value * 10.7,
            display_order: n,
            item_type: 'server_license',
            value: value,
            serial: "sslcomwc256ssl#{n}yrsl",
            published_as: 'live'
          )
          value += 365
        end
        value = 365
        group_duration = certificate.product_variant_groups.create(
          title: 'Duration',
          status: 'live',
          description: 'Duration',
          text_only_description: 'Duration',
          display_order: 1,
          serial: nil,
          published_as: 'live'
        )
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title: "#{n} Years",
            status: 'live',
            description: "#{n} years",
            text_only_description: "#{n} years",
            amount: value * 10.7,
            display_order: n,
            item_type: 'duration',
            value: value,
            serial: "sslcomwc256ssl#{n}yr",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # 103 High Assurance SSL (ov256sslcom)
    # ==========================================================================
    trait :ovssl do
      title                 { 'High Assurance SSL' }
      serial                { 'ov256sslcom' }
      product               { 'high_assurance' }
      icons                 { { main: 'gold_lock_lg.gif' } }
      display_order         { { all: 3, index: 2 } }
      description           do
        { certificate_type: 'High Assurance',
          points: "<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n",
          validation_level: 'Class 2 DoD',
          summary: "standard ssl\n",
          abbr: 'High Assurance SSL' }.with_indifferent_access
      end

      after(:create) do |certificate|
        value = 365
        group = certificate.product_variant_groups.create(
          title: 'Duration',
          status: 'live',
          description: 'Duration',
          text_only_description: 'Duration',
          display_order: 1,
          serial: nil,
          published_as: 'live'
        )

        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group.id,
            title: "#{n} Years",
            status: 'live',
            description: "#{n} years",
            text_only_description: "#{n} years",
            amount: value * 10.7,
            display_order: n,
            item_type: 'duration',
            value: value,
            serial: "sslcomov256ssl#{n}yr",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # 104 Free SSL (ov256sslcom)
    # ==========================================================================
    trait :freessl do
      title                 { 'Free SSL' }
      summary               { "90-day Basic SSL trial\n" }
      text_only_summary     { nil }
      text_only_description { nil }
      allow_wildcard_ucc    { nil }
      serial                { 'dv256sslcom' }
      product               { 'free' }
      icons                 { { main: 'silver_lock_lg.gif' } }
      display_order         { { all: 5, index: 3 } }
      description           do
        { certificate_type: 'Free',
          points: "<div class='check'>great for testing or development</div>\n<div class='check'>is free with no cost to you</div>\n<div class='check'>activates SSL Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<div class='check'>quick issuance</div>\n",
          validation_level: 'Class 1 DoD',
          summary: "90-day Basic SSL trial\n",
          abbr: 'Free SSL' }.with_indifferent_access
      end

      after(:create) do |certificate|
        group = certificate.product_variant_groups.create(
          title: 'Duration',
          status: 'live',
          description: 'Duration',
          text_only_description: 'Duration',
          display_order: 1,
          serial: nil,
          published_as: 'live'
        )

        ProductVariantItem.create(
          product_variant_group_id: group.id,
          title: '90 Days',
          status: 'live',
          description: '90 days',
          text_only_description: '90 days',
          amount: 0,
          display_order: 1,
          item_type: 'duration',
          value: 90,
          serial: 'dv256ssl1yr',
          published_as: 'live'
        )
      end
    end

    # Premium SSL (premium256sslcom)
    # ==========================================================================
    trait :premiumssl do
      title                 { 'Premium Multi-subdomain SSL' }
      serial                { 'premium256sslcom' }
      product               { 'premiumssl' }
      icons                 { { main: 'silver_locks_lg.gif' } }
      display_order         { { all: 6, index: 6 } }
      description           do
        { certificate_type: 'Premium SSL',
          points: "<div class='check'>quick domain validation</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$10,000 USD insurance guarranty</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n",
          validation_level: 'domain',
          summary: "ssl for up to 3 subdomains\n",
          abbr: 'Premium SSL' }.with_indifferent_access
      end

      after(:create) do |certificate|
        # Domain
        group_domain = certificate.product_variant_groups.create(
          title: 'Domains',
          status: 'live',
          description: 'Domain Names',
          text_only_description: 'Domain Names',
          display_order: 2,
          serial: nil,
          published_as: 'live'
        )
        # For 3 Domains
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title: "#{n} Year Domain For 3 Domains (ea domain)",
            status: 'live',
            description: "#{n} year domain for 3 domains (ea domain)",
            text_only_description: "#{n} year domain for 3 domains (ea domain)",
            amount: value * 10.7,
            display_order: n,
            item_type: 'ucc_domain',
            value: value,
            serial: "sslcompremium256ssl#{n}yrdm",
            published_as: 'live'
          )
          value += 365
        end
        # For Domains 4-200
        value = 365
        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_domain.id,
            title: "#{n} Year Domain For Domains 4-200 (ea domain)",
            status: 'live',
            description: "#{n} Year Domain For Domains 4-200 (ea domain)",
            text_only_description: "#{n} Year Domain For Domains 4-200 (ea domain)",
            amount: value * 10.7,
            display_order: n,
            item_type: 'ucc_domain',
            value: value,
            serial: "sslcompremium256ssl#{n}yradm",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # 350 Code Signing SSL (codesigning256sslcom)
    # ==========================================================================
    trait :codesigningssl do
      title                 { 'Code Signing' }
      serial                { 'codesigning256sslcom' }
      product               { 'code-signing' }
      icons                 { { main: 'gold_lock_lg.gif' } }
      display_order         { { all: 3, index: 2 } }
      description           do
        { certificate_type: 'Code Signing',
          points: "<div class='check'>organization validation</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$150,000 USD insurance guarranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>",
          validation_level: 'organization',
          summary: 'for securing installable apps and plugins',
          abbr: 'Code Signing' }.with_indifferent_access
      end

      after(:create) do |certificate|
        value = 2190
        group_duration = certificate.product_variant_groups.create(
          title: 'Duration',
          status: 'live',
          description: 'Duration',
          text_only_description: 'Duration',
          display_order: 1,
          serial: nil,
          published_as: 'live'
        )

        (6..10).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title: "#{n} Years",
            status: 'live',
            description: "#{n} years",
            text_only_description: "#{n} years",
            amount: value * 10.7,
            display_order: n,
            item_type: 'duration',
            value: value,
            serial: "sslcomcodesigning256ssl#{n}yr",
            published_as: 'live'
          )
          value += 365
        end
      end
    end

    # 360 EV Code Signing SSL (evcodesigning256sslcom)
    # ==========================================================================
    trait :evcodesigningssl do
      title                 { 'EV Code Signing' }
      serial                { 'evcodesigning256sslcom' }
      product               { 'ev-code-signing' }
      icons                 { { main: 'gold_lock_lg.gif' } }
      display_order         { { all: 3, index: 2 } }
      description           do
        { certificate_type: 'EV Code Signing',
          points: "<div class='check'>extended validation</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$2 million USD insurance guarranty</div>\n<div class='check'>works with Microsfot Smartscreen</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>stored on fips 140-2 USB token</div>\n<div class='check'>24 hour support</div>",
          validation_level: 'extended',
          summary: 'for securing installable apps and plugins',
          abbr: 'EV Code Signing' }.with_indifferent_access
      end

      after(:create) do |certificate|
        value = 365
        group_duration = certificate.product_variant_groups.create(
          title: 'Duration',
          status: 'live',
          description: 'Duration',
          text_only_description: 'Duration',
          display_order: 1,
          serial: nil,
          published_as: 'live'
        )

        (1..3).to_a.each do |n|
          ProductVariantItem.create(
            product_variant_group_id: group_duration.id,
            title: "#{n} Years",
            status: 'live',
            description: "#{n} years",
            text_only_description: "#{n} years",
            amount: value * 10.7,
            display_order: n,
            item_type: 'duration',
            value: value,
            serial: "sslcomevcodesigning256ssl#{n}yr",
            published_as: 'live'
          )
          value += 365
        end
      end
    end
  end
end
