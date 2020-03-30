require 'rails_helper'

RSpec.describe 'DomainValidations', type: :feature do
  context 'with email dcv method' do
    let(:cname) { create(:certificate_name, :with_dcv) }

    before do
      cname.domain_control_validation.update(dcv_method: 'email')
    end

    it 'return nil when calling dcv_verify' do
      response = cname.dcv_verify
      expect(response).to be_falsey
    end
  end
end
