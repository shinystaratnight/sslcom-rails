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

require 'rails_helper'

describe ResellerTier do
  subject { build_stubbed(:reseller_tier, :professional) }

  context 'associations' do
    it{ is_expected.to have_many(:certificates) }
    it{ is_expected.to have_many(:product_variant_groups).through(:certificates) }
    it{ is_expected.to have_many(:product_variant_items).through(:certificates) }
    it{ is_expected.to have_many(:resellers) }
  end

  describe '.generate_tier' do
    before do
      stub_roles
      SslAccount.any_instance.stubs(:initial_setup).returns(true)
    end

    let!(:resellers) { create_list(:reseller, 2) }

    it 'assigns attributes correctly' do
      tier = described_class.generate_tier(
        label: '7',
        description: { 'ideal_for' => 'enterprise organizations' },
        discount_rate: 0.35,
        amount: 5_000_000,
        roles: 'tier_7_reseller',
        reseller_ids: resellers.map(&:id)
      )
      'enterprise organizations'.should eq tier.description['ideal_for']
      'live'.should eq tier.published_as
      5_000_000.should eq tier.amount
      'tier_7_reseller'.should eq tier.roles
      resellers.map(&:id).should eq tier.resellers.map(&:id)
      '7'.should eq tier.label
    end
  end
end
