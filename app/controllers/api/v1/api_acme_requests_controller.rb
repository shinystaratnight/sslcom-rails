module Api
  module V1
    class ApiAcmeRequestsController < APIController
      prepend_view_path 'app/views/api/v1/api_acme_requests'
      before_action :set_database, if: -> { request.host=~/^sandbox/ || request.host=~/^sws-test/ || request.host=~/ssl.local$/ }
      before_action :set_test, :record_parameters

      DURATION_ON_ACME_CERTIFICATE = 1  # 1 year certificate for all acme clients
      BEGIN_PKCS7_TAG = '-----BEGIN PKCS7-----'

      rescue_from Exception do |exception|
        render_500_error exception
      end

      rescue_from ActiveRecord::RecordInvalid do
        InvalidApiAcmeRequest.create parameters: params, response: @result.to_json
        if @result.errors[:credential].present?
          render_unathorized
        else
          render_errors(@result.errors, :not_found)
        end
      end

      wrap_parameters ApiAcmeRequest, include: [*(ApiAcmeRequest::ACCOUNT_ACCESSORS + ApiAcmeRequest::CREDENTIAL_ACCESSORS).uniq]

      def retrieve_hmac
        set_template 'retrieve_hmac'

        persist
        @result.hmac_key = @result.api_credential.hmac_key
        render_200_status
      end

      def retrieve_credentials
        set_template 'retrieve_credentials'

        persist
        @result.account_key = @result.api_credential.account_key
        @result.secret_key = @result.api_credential.secret_key
        render_200_status
      end

      def validations_info
        persist
        data = certificate_names.empty? ? certificate_names : certificate_names.decorate
        render json: data, each_serializer: CertificateNameSerializer, fields: %i[domain http_token dns_token validated], status: :ok
      end

      def validation_status
        persist
        if certificate_name_for_domain
          render json: certificate_name_for_domain.decorate, serializer: CertificateNameSerializer, fields: %i[validation_source status], status: :ok
        elsif domain = params[:domain]
          errors = { errors: [parameters: "no order matching #{domain} found"] }
          render_errors(errors, :not_acceptable)
        else
          errors = { errors: [parameters: 'domain is required'] }
          render_errors(errors, :not_acceptable)
        end
      end

      private

      # Verify the External Account Binding (EAB) and check that the account is in good standing to issue certificates
      def account_preflight(data)
        eab = data[:eab]

        payload_data = Base64.urlsafe_decode64(JSON.parse(eab)['payload'])
        external_account = JSON.parse(payload_data)['externalAccountBinding']
        kid = JSON.parse(Base64.urlsafe_decode64(external_account['protected']))['kid']

        api_credential = ApiCredential.find_by(account_key: kid.to_s)
        hmac = api_credential.hmac_key

        decoded_key = Base64.urlsafe_decode64(hmac)
        data = "#{external_account['protected']}.#{external_account['payload']}.#{external_account['signature']}"

        begin
          # Set true, in third argument, for verification
          JWT.decode data, decoded_key, true
        rescue StandardError => e
          return { result: 'error', error_details: 'Failed to verify eab.\n' + e.message }
        end

        ssl_account = api_credential.ssl_account
        account_is_locked = ssl_account.ssl_account_users.map(&:user_enabled).include?(false)

        if account_is_locked
          { result: 'error', error_details: 'This account is locked.' }
        else
          { result: 'ok' }
        end
      end

      # Verify that the certificate request doesn't conflict with any of our issuance criteria.
      # Issuance criteria includes
      #   - billing profile or account balance checking
      #   - domain blacklist/high risk checking
      def domain_preflight(data)
        domains = data['domains']

        # Check if domain is blacklisted or high risked
        offenses = Pillar::Authority::BlocklistEntry.matches_by_domain?(domains)
        return { result: 'error', error_details: 'Domains are associated with blacklist or high risked.' } unless offenses.empty?

        acme_account = AcmeAccount.find_by(acme_account: data['acme_account'])
        ssl_account = acme_account.api_credential.ssl_account

        return { result: 'ok' } if ssl_account.no_limt || ssl_account.billing_profiles.present?

        product = certificate_product(domains)
        certificate = find_certificate(product)
        amount = get_amount_for_certificate(certificate, fqdns)

        if ssl_account.funded_account.cents < amount
          { result: 'error', error_details: 'Not enough funds in the account to complete this request' }
        else
          { result: 'ok' }
        end
      end

      # Verify that CSR doesn't contain a public key associated with compromised key or Debian weak key.
      def csr_preflight(data)
        csr = data[:csr]
        # acme_account = data[:acme_account]
        # order = data[:order]

        begin
          openssl_request = OpenSSL::X509::Request.new(csr)
        rescue Exception => e
          return { result: 'error', error_details: e.message }
        end

        public_key = openssl_request.public_key
        return { result: 'error', error_details: 'Invalid CSR' } unless public_key.instance_of? OpenSSL::PKey::RSA

        fingerprint = Digest::SHA1.hexdigest "Modulus=#{public_key.n.to_s(16)}\n"
        if RejectKey.exists?({ fingerprint: fingerprint[20..-1], size: public_key.n.num_bits })
          { result: 'error', error_details: 'Public key is associated with Debian Weak key or Compromised key.' }
        else
          { result: 'ok' }
        end
      end

      # Create RA objects from the certificate
      def order_complete(data)
        acme_certificate = AcmeCertificate.find_by(acme_certificate_identifier: data['cert_id'])
        csr = acme_certificate.csr
        ssl_account = csr.ssl_account
        signed_certificate = data[:certificate]
        sans = get_sans(signed_certificate, data['cert_id'])

        cert_product = certificate_product(sans)
        certificate = find_certificate(cert_product)
        duration = certificate.duration_in_days(DURATION_ON_ACME_CERTIFICATE)

        co_params = { duration: duration}
        co = ssl_account.certificate_orders.build(co_params)
        certificate_content = CertificateContent.new(
          domains: sans,
          ca: certificate.cas.ssl_account_or_general_default(ssl_account).last
        )
        co.certificate_contents << certificate_content
        certificate_order = Order.setup_certificate_order(
          certificate: certificate,
          certificate_order: co,
          duration: duration / 365
        )

        order = ssl_account.purchase(certificate_order)
        order.cents = certificate_order.attributes_before_type_cast['amount'].to_f

        if certificate_content.valid?
          applied = apply_funds(
            certificate_order: certificate_order,
            ssl_account: ssl_account,
            order: order
          )
          return { result: 'error', error_details: 'Error occurred creating a certificate order.'} unless applied

          order.save

          # TODO: Change the workflow_state in certificate_content
        end
      end

      def apply_funds(options)
        order = options[:order]
        no_limit = options[:ssl_account].no_limit
        unless order.line_items.empty?
          paid = if no_limit
                   apply_to_monthly_account(options)
                 else
                   apply_to_funded_account(options)
                 end
          if paid
            order.mark_paid!
            options[:certificate_order].pay!(true)
          end
        end
      end

      def apply_to_monthly_account(options)
        ssl_account_id = options[:ssl_account].id
        order = options[:order]
        order.update(
          state: 'invoiced',
          invoice_id: Invoice.get_or_create_for_team(ssl_account_id).try(:id),
          approval: 'approved',
          invoice_description: Order::SSL_CERTIFICATE
        )
        options[:certificate_order].pay!(true)
        false
      end

      def apply_to_funded_account(options)
        applied = false
        order = options[:order]
        funded_account = options[:ssl_account].funded_account
        if funded_account.cents >= order.cents
          funded_account.cents -= order.cents
          funded_account.deduct_order = true
          applied = true
          Authorization::Maintenance::without_access_control do
            funded_account.save
          end
        end
        applied
      end

      def find_certificate(product)
        Certificate.for_sale.find_by(product: product)
      end

      # Decide the certificate product based on the array of domains
      def certificate_product(domains)
        host_names = []
        domain_names = []
        domains.each do |dn|
          ps_domain = PublicSuffix.parse(dn)
          trd = ps_domain.trd
          domain = ps_domain.domain
          host_names.push(trd) if trd && !host_names.include?(trd)
          domain_names.push(domain) if domain && !domain_names.include?(domain)
        end

        product = if domain_names.count > 1
                    'ucc'
                  else
                    if host_names.blank? || (host_names - ['www']).blank?
                      'basicssl'
                    elsif host_names.include?('*')
                      'wildcard'
                    else
                      'premiumssl'
                    end
                  end
        product
      end

      # Retrieve SANs from the signed certificate. cert_id is acme_cert_id.
      def get_sans(certificate, cert_id)
        cert_type = certificate.starts_with?(BEGIN_PKCS7_TAG) ? 'PKCS#7' : 'X.509'
        decoded = begin
                    if cert_type == 'PKCS#7'
                      sc_pem = "#{Rails.root}/tmp/sc_pem_#{cert_id}.cer"
                      File.open(sc_pem, 'wb') do |f|
                        f.write body + "\n"
                      end
                      CertUtil.decode_certificate sc_pem, 'pkcs7'
                    else
                      OpenSSL::X509::Certificate.new(certificate.strip)
                    end
                  rescue Exception
                    # Do nothing here
                    # because certificate is already pre-validated in the previous steps
                  end
        decoded.subject_alternative_names
      end

      # Deduce the amount of purchase based on certificate and array of domains to validate the account balance
      def get_amount_for_certificate(certificate, domains)
        duration = certificate.duration_in_days(DURATION_ON_ACME_CERTIFICATE)
        amount = 0

        if certificate.is_ucc?
          variants = certificate.items_by_domains.find_all { |item| item.value == duration.to_s }
          additional_domains = (domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
          amount += variants[0].amount * Certificate::UCC_INITIAL_DOMAINS_BLOCK

          # calculate wildcards by subtracting their total from additional_domains
          wildcards = 0
          if certificate.allow_wildcard_ucc? and domains.present?
            wildcards = domains.find_all{|d|d =~ /\A\*\./}.count
            additional_domains -= wildcards
          end

          amount += variants[1].amount * additional_domains if additional_domains > 0
          amount += variants[2].amount * wildcards if wildcards > 0
        else
          variant_item = certificate.items_by_duration.find { |item| item.value == duration.to_s }
          amount = variant_item.amount
        end

        amount
      end

      def certificate_names
        @result.certificate_order.certificate_content.certificate_names || CertificateName.none
      end

      def certificate_name_for_domain
        certificate_names.order(:created_at).where('name LIKE ?', "%#{params[:domain]}%").last if params[:domain]
      end

      def record_parameters
        @result = klass.new(api_acme_request) do |result|
          result.debug ||= params.fetch(:debug, false)
          result.action ||= params[:action]
          result.test = @test
          result.request_url = request.url
          result.parameters = params.to_utf8.to_json
          result.raw_request = request.raw_post.force_encoding('ISO-8859-1').encode('UTF-8')
          result.request_method = request.request_method
        end
      end

      def api_acme_request
        _wrap_parameters(params)['api_acme_request'] || params[:api_acme_request]
      end

      def klass
        case params[:action]
        when 'retrieve_hmac'
          ApiAcmeRetrieveCredential
        when 'retrieve_credentials'
          ApiAcmeRetrieveHmac
        when 'validations_info', 'validation_status'
          ApiAcmeRetrieveValidations
        end
      end

      def set_template(filename)
        @template = File.join('api', 'v1', 'api_acme_requests', filename)
      end

      def persist
        @result.validate!
        @result.save
      end
    end
  end
end
