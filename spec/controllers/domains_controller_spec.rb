# frozen_string_literal: false

require 'rails_helper'

describe DomainsController do
  include SessionHelper

  describe 'select csr route' do
    before do
      @user = FactoryBot.create(:user)
      activate_authlogic
      login_as(@user)
    end

    let(:csr) { FactoryBot.create(:csr, common_name: 'ssl.com') }
    let(:domain) { FactoryBot.build_stubbed(:domain) }

    before(:each) do
      @user.ssl_accounts << csr.ssl_account
    end

    describe 'create' do
      before do
        Timecop.freeze(DateTime.now)
      end

      after do
        Timecop.return
      end

      before(:each) do
        DomainControlValidation.destroy_all
      end

      xit 'creates a domain and dcv (email)' do
        ssl_slug = @user.ssl_accounts.first.ssl_slug
        post :create, team: ssl_slug, domain_names: 'support.ssl.com', format: :json

        dcv = DomainControlValidation.last
        # Developer Note: This route creates 2
        # validations either by accident or intentionally
        expect(Domain.count).to eq 1
        expect(DomainControlValidation.count).to eq 2
        expect(dcv.candidate_addresses).to include "admin@ssl.com"
        expect(dcv.candidate_addresses).to include "administrator@ssl.com"
        expect(dcv.candidate_addresses).to include "webmaster@ssl.com"
        expect(dcv.candidate_addresses).to include "hostmaster@ssl.com"
        expect(dcv.candidate_addresses).to include "postmaster@ssl.com"
        expect(dcv.dcv_method).to match 'email'
        expect(dcv.validation_compliance_id).to eq 2
        expect(dcv.identifier_found).to eq true
        expect(dcv.responded_at).to eq DateTime.now
        expect(dcv.workflow_state).to match /satisfied/
      end

      it 'does not create a dcv (email)' do
        ssl_slug = @user.ssl_accounts.first.ssl_slug
        post :create, team: ssl_slug, domain_names: 'doesnotmatchcsr.com', format: :json
        dcv = DomainControlValidation.last
        expect(DomainControlValidation.count).to eq 0
      end
    end

    context 'when no csr is selected' do
      it 'rerenders the select_csr page' do
        params = {
          authenticity_token: "dLDJFSLHJFkl;jad;klsjhGSHCKEGNJSHDH==",
          d_name_selected: ["#{domain.id}"],
        }

        ssl_slug = @user.ssl_accounts.first.ssl_slug
        post :validate_against_csr, team: ssl_slug, params: params
        expect(response).to have_http_status(302)
        expect(subject.request.flash[:error]).to_not be_nil
        expect(subject.request.flash[:error]).to match(/Please select an option to validate against CSR*/)
      end
    end
  end
end
