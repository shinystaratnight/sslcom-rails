# == Schema Information
#
# Table name: assignments
#
#  id             :integer          not null, primary key
#  created_at     :datetime
#  updated_at     :datetime
#  role_id        :integer
#  ssl_account_id :integer
#  user_id        :integer
#
# Indexes
#
#  index_assignments_on_role_id                                 (role_id)
#  index_assignments_on_ssl_account_id                          (ssl_account_id)
#  index_assignments_on_user_id                                 (user_id)
#  index_assignments_on_user_id_and_ssl_account_id              (user_id,ssl_account_id)
#  index_assignments_on_user_id_and_ssl_account_id_and_role_id  (user_id,ssl_account_id,role_id)
#

FactoryBot.define do
  factory :assignment do
    ssl_account
    # role
    # user

    trait :sysadmin do
      after(:create) do |assignment|
        assignment.role = create(:role, :sysadmin)
      end
    end

    trait :super_user do
      after(:create) do |assignment|
        assignment.role = create(:role, :super_user)
      end
    end

    trait :owner do
      after(:create) do |assignment|
        assignment.role = create(:role, :owner)
      end
    end

    trait :reseller do
      after(:create) do |assignment|
        assignment.role = create(:role, :reseller)
      end
    end

    trait :account_admin do
      after(:create) do |assignment|
        assignment.role = create(:role, :account_admin)
      end
    end

    trait :billing do
      after(:create) do |assignment|
        assignment.role = create(:role, :billing)
      end
    end

    trait :installer do
      after(:create) do |assignment|
        assignment.role = create(:role, :installer)
      end
    end

    trait :validations do
      after(:create) do |assignment|
        assignment.role = create(:role, :validations)
      end
    end

    trait :users_manager do
      after(:create) do |assignment|
        assignment.role = create(:role, :users_manager)
      end
    end
  end
end
