require 'rails_helper'

describe CsrUniqueValue do
  it { is_expected.to belong_to(:csr) }
  it { is_expected.to have_many(:domain_control_validations) }

  describe 'validations' do
    after do
      described_class.destroy_all
    end

    it 'will be unique' do
      csr_unique_value = FactoryBot.create(:csr_unique_value, unique_value: 'abcdef1234')
      csr = csr_unique_value.csr

      expect(described_class.new(unique_value: 'abcdef1234', csr_id: csr.id)).to_not be_valid
      expect(described_class.new(unique_value: 'xyz1234', csr_id: csr.id)).to be_valid
    end

    it 'should have a csr' do
      expect(described_class.new(unique_value: 'abcdef1234', csr_id: nil)).to_not be_valid
    end
  end
end
