# frozen_string_literal: true

# == Schema Information
#
# Table name: product_variant_groups
#
#  id                    :integer          not null, primary key
#  description           :text(65535)
#  display_order         :integer
#  published_as          :string(255)
#  serial                :string(255)
#  status                :string(255)
#  text_only_description :text(65535)
#  title                 :string(255)
#  variantable_type      :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  variantable_id        :integer
#
FactoryBot.define do
  factory :product_variant_group do
    title { 'Domains' }
    status { 'live' }
    description { 'Domain Names' }
    text_only_description { 'Domain Names' }
    published_as { 'live' }

    association :variantable, factory: %i[certificate evuccssl]
  end
end
