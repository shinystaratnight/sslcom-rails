require 'rails_helper'

class CertCreateWithNolimitUserTest < ActionDispatch::IntegrationTest
  include ApiSetupHelper

  describe 'create_v1_4' do
    before do
      # Change domain name to sws for API tests
      api_host = 'sws.sslpki.local'
      host! api_host

      # To prevent delayed workers from being executed immediately after a job is enqueued.
      # Currently in config/initializers/delayed_job.rb, it's configured like:
      # Delayed::Worker.delay_jobs = !Rails.env.test?
      Delayed::Worker.delay_jobs = true

      @user = FactoryBot.create(:user)
      @team = @user.ssl_account
      @team.update(no_limit: true)
      assert @user.valid?
    end

    after do
      # Revert Delayed configuration back after each example finishes
      Delayed::Worker.delay_jobs = !Rails.env.test?
    end

    it 'creates a certificate order for users with monthly unlimited amount' do
      request = {
        'account_key': @team.api_credential.account_key,
        'secret_key': @team.api_credential.secret_key,
        'product': '106',
        'period': '365',
        'server_software': '15',
        'organization_name': 'yoursite',
        'street_address_1': 'somewhere st',
        'locality_name': 'Houston',
        'state_or_province_name': 'Texas',
        'postal_code': '77777',
        'country': 'US',
        'duns_number': '1234567',
        'company_number': 'yoursite_number',
        'registered_country_name': 'US',
        'domains': {
          'www.yoursite.com': {
            'dcv': 'admin@yoursite.com'
          }
        }
      }
      post api_certificate_create_v1_4_path(request)
      items = JSON.parse(body)
      assert        response.success?
      assert_nil    items['validations']
      refute_nil    items['ref']
      refute_nil    items['registrant']
      refute_nil    items['order_amount']
      refute_nil    items['certificate_url']
      refute_nil    items['receipt_url']
      refute_nil    items['smart_seal_url']
      refute_nil    items['validation_url']
      assert_equal  1, @team.certificate_orders.count
      assert_equal  1, @team.orders.count
      assert_equal  1, @team.invoices.count
      order = @team.orders.first
      certificate_order = @team.certificate_orders.first
      assert_equal  order.state, 'invoiced'
      assert_equal  order.status, 'active'
      assert_equal  order.approval, 'approved'
      assert_equal  certificate_order.workflow_state, 'paid'
      assert_equal  order.cents, certificate_order.amount
    end
  end
end