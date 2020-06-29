# == Schema Information
#
# Table name: certificate_order_tokens
#
#  id                       :integer          not null, primary key
#  callback_datetime        :datetime
#  callback_method          :string(255)
#  callback_timezone        :string(255)
#  callback_type            :string(255)
#  due_date                 :datetime
#  is_callback_done         :boolean
#  is_expired               :boolean
#  locale                   :string(255)
#  passed_token             :string(255)
#  phone_call_count         :integer
#  phone_number             :string(255)
#  phone_verification_count :integer
#  status                   :string(255)
#  token                    :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  certificate_order_id     :integer
#  ssl_account_id           :integer
#  user_id                  :integer
#
# Indexes
#
#  index_certificate_order_tokens_on_certificate_order_id  (certificate_order_id)
#  index_certificate_order_tokens_on_ssl_account_id        (ssl_account_id)
#  index_certificate_order_tokens_on_user_id               (user_id)
#
FactoryBot.define do
  factory :certificate_order_token do
    callback_datetime { DateTime.now + 1.day }
    callback_method { 'call' }
    callback_timezone {}
    callback_type {}
    due_date { DateTime.now + 1.week }
    is_callback_done {}
    is_expired { false }
    locale { 'en' }
    passed_token { }
    phone_call_count { 0 }
    phone_number {}
    phone_verification_count { 0 }
    status { 'pending' }
    token { Faker::Alphanumeric.alpha(number: 10) }
    certificate_order

    trait :manual do
      callback_type { 'manual' }
    end
  end
end
