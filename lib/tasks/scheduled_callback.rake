namespace 'scheduled_callback' do
  desc "Scan certificate order tokens for scheduled callback and call"
  task scan_scheduled_callback: :environment do
    CertificateOrderToken.scheduled_callback.each do |co_token|
      phone_call_count = co_token.phone_call_count.nil? ? 0 : co_token.phone_call_count.to_i

      if phone_call_count < CertificateOrderToken::PHONE_CALL_LIMIT_MAX_COUNT
        # Generate new passed token.
        passed_token = (SecureRandom.hex(8)+co_token.passed_token)[0..19]
        co_token.update_column :passed_token, passed_token

        # Increase phone call count.
        phone_call_count = co_token.phone_call_count.to_i + 1
        co_token.update_column :phone_call_count, phone_call_count

        # Get phone number and country from locked_registrant of certificate_order.
        phone_number = co_token.certificate_order.locked_registrant.phone || ''
        country_code = co_token.certificate_order.locked_registrant.country_code || '1'

        # Call by SMS
        @response = Authy::PhoneVerification.start(
            via: 'sms',
            country_code: country_code,
            phone_number: phone_number
        )

        if @response.ok?
          # Update is_callback_done
          co_token.update_column :is_callback_done, true
        else
          # Call by Voice
          @response = Authy::PhoneVerification.start(
              via: 'call',
              country_code: country_code,
              phone_number: phone_number
          )

          # Update is_callback_done
          co_token.update_column :is_callback_done, true if @response.ok?
        end
      else
        # Update status column
        co_token.update_column :status, CertificateOrderToken::FAILED_STATUS
      end
    end
  end
end