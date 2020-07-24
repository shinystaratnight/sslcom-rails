# frozen_string_literal: true

# == Schema Information
#
# Table name: cdns
#
#  id                   :integer          not null, primary key
#  api_key              :string(255)
#  custom_domain_name   :string(255)
#  is_ssl_req           :boolean          default("0")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  certificate_order_id :integer
#  resource_id          :string(255)
#  ssl_account_id       :integer
#
# Indexes
#
#  fk_rails_486d5cc190           (certificate_order_id)
#  index_cdns_on_resource_id     (resource_id)
#  index_cdns_on_ssl_account_id  (ssl_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (certificate_order_id => certificate_orders.id) ON DELETE => restrict ON UPDATE => restrict
#

FactoryBot.define do
  factory :cdn do
  end
end
