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

  it{ is_expected.to have_many(:certificates) }
  it{ is_expected.to have_many(:product_variant_groups).through(:certificates) }
  it{ is_expected.to have_many(:product_variant_items).through(:certificates) }
  it{ is_expected.to have_many(:resellers) }

  describe '.generate_tier' do
    let!(:resellers) { create_list(:reseller, 2) }

    it 'assigns attributes correctly' do
      tier = described_class.generate_tier(
        label: 'test',
        description: { 'ideal_for' => 'enterprise organizations' },
        discount_rate: 0.35,
        amount: 5_000_000,
        roles: 'tier_test_reseller',
        reseller_ids: resellers.map(&:id)
      )
      expect(tier.description['ideal_for']).to eq 'enterprise organizations'
      expect(tier.published_as).to eq 'live'
      expect(tier.amount).to eq 5_000_000
      expect(tier.roles).to eq 'tier_test_reseller'
      expect(tier.resellers.map(&:id)).to eq resellers.map(&:id)
      expect(tier.label).to eq 'test'
    end
  end
end
