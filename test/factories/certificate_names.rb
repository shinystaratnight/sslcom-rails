# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_names
#
#  id                     :integer          not null, primary key
#  caa_passed             :boolean          default(FALSE)
#  email                  :string(255)
#  is_common_name         :boolean
#  name                   :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  acme_account_id        :string(255)
#  certificate_content_id :integer
#  ssl_account_id         :integer
#
# Indexes
#
#  index_certificate_names_on_certificate_content_id  (certificate_content_id)
#  index_certificate_names_on_name                    (name)
#  index_certificate_names_on_ssl_account_id          (ssl_account_id)
#

FactoryBot.define do
  factory :certificate_name do
    name { Faker::Internet.domain_name }
    caa_passed { false }
    email { Faker::Internet.email }
    is_common_name { true }

    association :ssl_account, factory: :ssl_account

    after :create do |cn|
      cn.certificate_content = create(:certificate_content, :with_csr, certificate_order: create(:certificate_order))
      cn.save
    end
  end
end
