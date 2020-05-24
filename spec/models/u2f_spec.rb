# frozen_string_literal: true

# == Schema Information
#
# Table name: u2fs
#
#  id          :integer          not null, primary key
#  certificate :text(65535)
#  counter     :integer          default("0"), not null
#  key_handle  :string(255)
#  nick_name   :string(255)
#  public_key  :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  user_id     :integer
#
# Indexes
#
#  index_u2fs_on_user_id  (user_id)
#

require 'rails_helper'

describe U2f do
  let!(:u2f) { create(:u2f) }

  describe 'attributes' do
    it { is_expected.to have_db_column :nick_name }
    it { is_expected.to have_db_column :key_handle }
    it { is_expected.to have_db_column :user_id }
    it { is_expected.to have_db_column :certificate }
    it { is_expected.to have_db_column :public_key }
    it { is_expected.to have_db_column :counter }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    let(:u2f) { build(:u2f) }

    it 'is valid' do
      expect(u2f).to be_valid
    end

    it { is_expected.to validate_presence_of(:nick_name) }
    it { is_expected.to validate_presence_of(:key_handle) }
  end
end
