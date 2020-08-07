# frozen_string_literal: true
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
