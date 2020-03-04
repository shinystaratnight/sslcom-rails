# frozen_string_literal: true

# == Schema Information
#
# Table name: reseller_tiers
#
#  id           :integer          not null, primary key
#  amount       :integer
#  description  :string(255)
#  label        :string(255)
#  published_as :string(255)
#  roles        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

require 'test_helper'

describe ResellerTier do
  before :all do
    stub_roles
    stub_triggers
    stub_server_software
  end

  subject { build(:reseller_tier, :professional) }

  context 'associations' do
    should have_many(:certificates)
    should have_many(:product_variant_groups).through(:certificates)
    should have_many(:product_variant_items).through(:certificates)
    should have_many(:resellers)
  end

  describe '.generate_tier' do
    let!(:resellers) { create_list(:reseller, 2) }
    let!(:tier) do
      ResellerTier.generate_tier(
        label: '7',
        description: { 'ideal_for' => 'enterprise organizations' },
        discount_rate: 0.35,
        amount: 5_000_000,
        roles: 'tier_7_reseller',
        reseller_ids: resellers.map(&:id)
      )
    end

    it 'assigns description correctly' do
      assert_equal 'enterprise organizations', tier.description['ideal_for']
    end

    it 'assigns published_as correctly' do
      assert_equal 'live', tier.published_as
    end

    it 'assigns amount correctly' do
      assert_equal 5_000_000, tier.amount
    end

    it 'assigns roles correctly' do
      assert_equal 'tier_7_reseller', tier.roles
    end

    it 'assigns resellers correctly' do
      assert_equal resellers.map(&:id), tier.resellers.map(&:id)
    end

    it 'assigns label correctly' do
      assert_equal '7', tier.label
    end
  end
end
