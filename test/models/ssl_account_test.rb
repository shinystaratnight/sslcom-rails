# frozen_string_literal: true

# == Schema Information
#
# Table name: ssl_accounts
#
#  id                     :integer          not null, primary key
#  acct_number            :string(255)
#  billing_method         :string(255)      default("monthly")
#  company_name           :string(255)
#  duo_enabled            :boolean
#  duo_own_used           :boolean
#  epki_agreement         :datetime
#  issue_dv_no_validation :string(255)
#  no_limit               :boolean          default(FALSE)
#  roles                  :string(255)      default([])
#  sec_type               :string(255)
#  ssl_slug               :string(255)
#  status                 :string(255)
#  workflow_state         :string(255)      default("active")
#  created_at             :datetime
#  updated_at             :datetime
#  default_folder_id      :integer
#
# Indexes
#
#  index_ssl_account_on_acct_number                                 (acct_number)
#  index_ssl_accounts_an_cn_ss                                      (acct_number,company_name,ssl_slug)
#  index_ssl_accounts_on_acct_number_and_company_name_and_ssl_slug  (acct_number,company_name,ssl_slug)
#  index_ssl_accounts_on_default_folder_id                          (default_folder_id)
#  index_ssl_accounts_on_id_and_created_at                          (id,created_at)
#  index_ssl_accounts_on_ssl_slug_and_acct_number                   (ssl_slug,acct_number)
#

require 'test_helper'

describe SslAccount do
  subject { build(:ssl_account) }

  before :all do
    stub_roles
    stub_triggers
    stub_server_software
  end

  context 'attributes' do
    # before(:each) { @ssl_acct = build(:ssl_account) }
    should have_db_column :acct_number
    should have_db_column :roles
    should have_db_column :status
    should have_db_column :ssl_slug
    should have_db_column :company_name
  end

  describe 'validations' do
    it '#ssl_slug should NOT be valid under 2 characters' do
      subject.ssl_slug = 'a'
      subject.validate

      assert_equal ['is too short (minimum is 2 characters)'], subject.errors.messages[:ssl_slug]
    end
    it '#ssl_slug should NOT be valid when over 20 characters' do
      subject.ssl_slug = 'overtwentycharacterslong'
      subject.validate

      assert_equal ['is too long (maximum is 20 characters)'], subject.errors.messages[:ssl_slug]
    end
    it '#ssl_slug should NOT be valid when empty string' do
      subject.ssl_slug = ''
      subject.validate

      assert_equal ['is too short (minimum is 2 characters)'], subject.errors.messages[:ssl_slug]
    end
    it '#ssl_slug should NOT be valid when not unique' do
      @dupe = create(:ssl_account, ssl_slug: 'dupe')
      subject.ssl_slug = 'dupe'
      subject.validate

      assert_equal ['has already been taken'], subject.errors.messages[:ssl_slug]
    end
    it '#ssl_slug should ignore case' do
      @dupe = create(:ssl_account, ssl_slug: 'dupe')
      subject.ssl_slug = 'DUPE'
      subject.validate

      assert_equal ['has already been taken'], subject.errors.messages[:ssl_slug]
    end
    it '#ssl_slug should be valid when nil' do
      subject.ssl_slug = nil
      subject.validate

      assert subject.valid?
    end
    it '#company_name should NOT be valid under 2 characters' do
      subject.company_name = 'a'
      subject.validate

      assert_equal ['is too short (minimum is 2 characters)'], subject.errors.messages[:company_name]
    end
    it '#company_name should NOT be valid when over 20 characters' do
      subject.company_name = 'overtwentycharacterslong'
      subject.validate

      assert_equal ['is too long (maximum is 20 characters)'], subject.errors.messages[:company_name]
    end
    it '#company_name should NOT be valid when empty string' do
      subject.company_name = ''
      subject.validate

      assert_equal ['is too short (minimum is 2 characters)'], subject.errors.messages[:company_name]
    end
    it '#company_name should be valid when nil' do
      subject.company_name = nil
      subject.validate

      assert subject.valid?
    end
  end

  describe 'slug string validation' do
    it '#ssl_slug_valid? string "company" should be valid' do
      assert SslAccount.ssl_slug_valid?('company')
    end
    it '#ssl_slug_valid? string w/underscore should be valid' do
      assert SslAccount.ssl_slug_valid?('company_1')
    end
    it '#ssl_slug_valid? string w/dash should be valid' do
      assert SslAccount.ssl_slug_valid?('company-1')
    end
    it '#ssl_slug_valid? string w/digits should be valid' do
      assert SslAccount.ssl_slug_valid?('20160102')
    end
    it '#ssl_slug_valid? string using symbols should NOT be valid' do
      (%w[~ ! @ # $ % ^ & * ( ) = ` < > ? . , | [ ] / ; : ' "] + ['{', '}']).each do |symbol|
        refute SslAccount.ssl_slug_valid?("team_#{symbol}")
      end
    end
    it '#ssl_slug_valid? string using route names should NOT be valid' do
      %w[oauth_clients managed_users user_session].each do |named_route|
        refute SslAccount.ssl_slug_valid?(named_route)
      end
    end
    it '#ssl_slug_valid? string not unique should NOT be valid' do
      create(:ssl_account, ssl_slug: 'dupe')
      refute SslAccount.ssl_slug_valid?('dupe')
    end
  end

  # describe 'helper methods' do
  #   it '#get_account_owner returns correct user/owner' do
  #     target_user = create(:user, :owner)
  #     target_ssl  = target_user.assignments.first.ssl_account
  #     new_user = create(:user)
  #     # byebug
  #     # other_user  = create_and_approve_user(target_ssl, 'other_user')
  #     new_user.ssl_accounts << target_ssl
  #     new_user.set_roles_for_account(target_ssl, [create(:role, :account_admin).id])
  #     new_user.send(:approve_account, ssl_account_id: target_ssl.id)
  #     # byebug
  #     assert_equal target_user, target_ssl.get_account_owner
  #     # refute_equal other_user, target_ssl.get_account_owner
  #   end
  # end

  # describe 'helper methods' do
  #   it '#get_account_owner returns correct user/owner' do
  #     target_user = create(:user, :owner)
  #     target_ssl  = target_user.ssl_account
  #     other_user  = create_and_approve_user(target_ssl, 'other_user')

  #     assert_equal target_user, target_ssl.get_account_owner
  #     refute_equal other_user, target_ssl.get_account_owner
  #   end
  # end
end
