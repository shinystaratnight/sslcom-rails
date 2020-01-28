# == Schema Information
#
# Table name: tags
#
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  ssl_account_id :integer          not null
#  taggings_count :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :tag do
    name  { Faker::Internet.slug }
    ssl_account
  end
end
