# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  taggings_count :integer          default("0"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  ssl_account_id :integer          not null
#
# Indexes
#
#  index_tags_on_ssl_account_id           (ssl_account_id)
#  index_tags_on_ssl_account_id_and_name  (ssl_account_id,name)
#  index_tags_on_taggings_count           (taggings_count)
#

FactoryBot.define do
  factory :tag do
    name  { Faker::Internet.slug }
    ssl_account

    to_create { |cc| cc.save!(validate: false) }
  end
end
