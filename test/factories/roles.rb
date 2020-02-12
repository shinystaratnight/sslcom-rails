# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id             :integer          not null, primary key
#  description    :text(65535)
#  name           :string(255)
#  status         :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  ssl_account_id :integer
#
# Indexes
#
#  index_roles_on_ssl_account_id  (ssl_account_id)
#

FactoryBot.define do
  factory :role do
    name { 'owner' }
    description {}
    status {}
  end

  trait :account_admin do
    name { 'account_admin' }
    description { 'Access to all tasks related to managing entire account and team except altering user who owns the ssl team.' }
  end

  trait :billing do
    name { 'billing' }
    description { 'Access to billing tasks for team. Tasks include creating or deleting billing profiles, managing transactions and renewing certificate orders.' }
  end

  trait :installer do
    name { 'installer' }
    description { 'Access to completed certificate and site seal, also has the ability to submit initial CSR and rekey/reprocess the certificate.' }
  end

  trait :owner do
    name { 'owner' }
    description { 'Access to all tasks related to managing entire account and team including transferring ownership of the team.' }
  end

  trait :reseller do
    name { 'reseller' }
    description { 'Reseller.' }
  end

  trait :super_user do
    name { 'super_user' }
    description { 'All permissions to everything.' }
  end

  trait :sysadmin do
    name { 'sysadmin' }
    description { 'Permissions to everything except SSL.com CA.' }
  end

  trait :users_manager do
    name { 'users_manager' }
    description { "Manage teams' users. Tasks include inviting users to team, removing, editing roles, disabling and enabling teams' users." }
  end

  trait :validations do
    name { 'validations' }
    description { 'Access to validation tasks for the Team. Tasks include uploading validation documents, selecting the validation method, and other related tasks.' }
  end

  trait :ra_admin do
    name { 'ra_admin' }
    description { 'Can manage RA system settings like product configurations and mappings.' }
  end

  trait :individual_certificate do
    name { 'individual_certificate' }
    description { 'Access to only certificate orders assigned to this user in a given team.' }
  end
end
