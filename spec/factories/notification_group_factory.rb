# == Schema Information
#
# Table name: notification_groups
#
#  id             :integer          not null, primary key
#  friendly_name  :string(255)      not null
#  notify_all     :boolean          default("1")
#  ref            :string(255)      not null
#  scan_port      :string(255)      default("443")
#  status         :boolean
#  created_at     :datetime
#  updated_at     :datetime
#  ssl_account_id :integer
#
# Indexes
#
#  index_notification_groups_on_ssl_account_id          (ssl_account_id)
#  index_notification_groups_on_ssl_account_id_and_ref  (ssl_account_id,ref)
#

FactoryBot.define do
  factory :notification_group do
    friendly_name { "ng-co-" + Faker::Alphanumeric.alpha(number: 10) }
    notify_all { true }
    ref { "ng-" + Faker::Alphanumeric.alpha(number: 10) }
    scan_port { '443'}
    # Note: A status of true means "disabled"
    status { false }
    ssl_account
  end
end
