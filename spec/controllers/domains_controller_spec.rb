# frozen_string_literal: false

require 'rails_helper'

describe DomainsController do
  include SessionHelper
  let(:user) { create(:user) }

  before do
    activate_authlogic
    login_as(user)
  end

  describe 'validate_selected' do
    context 'email' do
      it 'redirects to dcv_all_validate (success)' do
        domain = FactoryBot.create(:domain, name: 'avengers.com', is_common_name: nil, email: nil, ssl_account_id: user.ssl_accounts.first.id)
        team = user.ssl_accounts.first.acct_number
        params = {
          authenticity_token: 'afjadfjaslkdjfalsfd13741', dcv_address: ['admin@avengers.com'], d_name_id: [domain.id]
        }

        described_class.stubs(:send_validation_email).with(params).returns(true)
        get :validate_selected, team: team, authenticity_token: 'afjadfjaslkdjfalsfd13741', dcv_address: ['admin@avengers.com'], d_name_id: [domain.id]

        expect(subject.request.flash[:notice]).not_to be_nil
        expect(subject.request.flash[:notice]).to match /Please check your email for the validation code and submit it below to complete validation./
        expect(response).to redirect_to :dcv_all_validate_domains
      end

      it 'redirects to dcv_all_validate (failure)' do
        domain = FactoryBot.create(:domain, name: 'avengers.com', is_common_name: nil, email: nil, ssl_account_id: user.ssl_accounts.first.id)
        team = user.ssl_accounts.first.acct_number
        params = {
          authenticity_token: 'afjadfjaslkdjfalsfd13741', dcv_address: [''], d_name_id: [domain.id]
        }

        described_class.stubs(:send_validation_email).with(params).returns(false)
        get :validate_selected, team: team, authenticity_token: 'afjadfjaslkdjfalsfd13741', dcv_address: [''], d_name_id: [domain.id]

        expect(subject.request.flash[:error]).not_to be_nil
        expect(subject.request.flash[:error]).to match /Please select a valid email address./
        expect(response).to redirect_to :dcv_all_validate_domains
      end
    end
  end

  describe 'create' do
    context 'creating a domain with an existing associated validated csr' do
      before do
        Timecop.freeze(DateTime.now)
      end

      after do
        Timecop.return
      end

      context 'email' do
        it 'creates a domain and dcv' do
          certificate_name = FactoryBot.create(:certificate_name, :with_email_dcv)
          certificate_name.ssl_account_id = user.ssl_accounts.first.id
          certificate_name.save

          post :create, team: user.ssl_accounts.first.ssl_slug, domain_names: "support.#{certificate_name.name}", format: :json

          domain = Domain.find_by(name: "support.#{certificate_name.name}")
          dcv = domain.domain_control_validations.last

          expect(dcv.email_address).to eq "admin@#{certificate_name.name}"
          expect(dcv.candidate_addresses).to include "admin@#{certificate_name.name}"
          expect(dcv.candidate_addresses).to include "administrator@#{certificate_name.name}"
          expect(dcv.candidate_addresses).to include "webmaster@#{certificate_name.name}"
          expect(dcv.candidate_addresses).to include "hostmaster@#{certificate_name.name}"
          expect(dcv.candidate_addresses).to include "postmaster@#{certificate_name.name}"
          expect(dcv.dcv_method).to match 'email'
          expect(dcv.validation_compliance_id).to eq 2
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end
      end
    end
  end

  describe 'select_csr' do
    context 'when no csr is selected' do
      it 'rerenders the select_csr page' do
        domain = FactoryBot.create(:domain)
        params = {
          authenticity_token: 'dLDJFSLHJFkl;jad;klsjhGSHCKEGNJSHDH==',
          d_name_selected: [domain.id.to_s]
        }

        ssl_slug = user.ssl_accounts.first.ssl_slug
        post :validate_against_csr, team: ssl_slug, params: params
        expect(response).to have_http_status(302)
        expect(subject.request.flash[:error]).not_to be_nil
        expect(subject.request.flash[:error]).to match(/Please select an option to validate against CSR*/)
      end
    end
  end
end
