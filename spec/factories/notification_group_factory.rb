FactoryBot.define do
  factory :notification_group do
    friendly_name { 'ng-co-' + Faker::Alphanumeric.alpha(number: 10) }
    notify_all { true }
    ref { 'ng-' + Faker::Alphanumeric.alpha(number: 10) }
    scan_port { '443' }
    # Note: A status of true means "disabled"
    status { false }
    ssl_account
  end
end
