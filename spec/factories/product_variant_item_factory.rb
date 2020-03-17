# frozen_string_literal: true

# == Schema Information
#
# Table name: product_variant_items
#
#  id                       :integer          not null, primary key
#  amount                   :integer
#  description              :text(65535)
#  display_order            :integer
#  item_type                :string(255)
#  published_as             :string(255)
#  serial                   :string(255)
#  status                   :string(255)
#  text_only_description    :text(65535)
#  title                    :string(255)
#  value                    :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  product_variant_group_id :integer
#
# Indexes
#
#  index_product_variant_items_on_product_variant_group_id  (product_variant_group_id)
#
FactoryBot.define do
  factory :product_variant_item do
    title { '1 Year Domain For 3 Domains (ea domain)' }
    status { 'live' }
    description { '1 year domain for 3 domains (ea domain)' }
    text_only_description { '1 year domain for 3 domains (ea domain)' }
    amount { 5900 }
    item_type { 'ucc_domain' }
    value { '365' }
    serial { 'sslcomucc256ssl1yrdm' }
    published_as { 'live' }

    product_variant_group
  end
end
