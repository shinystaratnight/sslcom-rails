require 'spec_helper'

describe ComodoApi do
  context "when applying for certificate" do
    it "returns the certificate_id" do
      ComodoApi.apply_for_certificate create(:completed_unvalidated_dv_certificate_order)
    end
  end

end
