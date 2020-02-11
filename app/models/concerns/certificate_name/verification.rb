# frozen_string_literal: true

module Concerns
  module CertificateName
    module Verification
      extend ActiveSupport::Concern

      def dcv_verify(protocol = nil)
        protocol ||= domain_control_validation.try(:dcv_method)
        return nil if protocol =~ /email/

        validation_type = protocol.include? 'acme' ? 'acme-challenge' : 'pki-validation'
        key = protocol.include? 'acme' ? domain_control_validation.acme_token : csr.md5_hash
        options = { secure: true, prepend: '', check_type: true, validation_type: validation_type, key: key }
        parameters = { https_dcv_url: dcv_url(options), http_dcv_url: dcv_url(options.merge(secure: false)),
                       cname_origin: cname_origin(true), cname_destination: cname_destination, csr: csr, ca_tag: ca_tag }
        self.class.dcv_verify(protocol, parameters)
      end

      def verify_challenge(response, options, is_acme)
        is_acme ? acme_verified(response, options) : standard_verified(response, options)
      end

      def standard_verified(response, options)
        csr = options[:csr]
        true if !!(
        if response =~ Regexp.new("^#{csr.sha2_hash}") &&
            (has_ssl_ca_tag ? true : response =~ Regexp.new("^#{options[:ca_tag]}")) &&
            unique_value_accepted(csr.unique_value, options[:ignore_unique_value])
          true
        else
          response =~ /"^#{csr.unique_value}"/
        end)
      end

      def has_ssl_ca_tag(ca_tag)
        ca_tag == I18n.t('labels.ssl_ca')
      end

      def unique_value_accepted(unique_value, ignored)
        unique_value.blank? || ignored
      end

      def acme_verified(response)
        self.class.acme_verify(response)
      end

      def api_credential
        certificate_content&.ssl_account&.api_credential
      end

      def hmac_key
        api_credential&.hmac_key
      end

      def thumbprint
        api_credential&.acme_acct_pub_key_thumbprint
      end

      def verified
        well_formed && token_matches && thumbprint_matches
      end

      def well_formed
        return true if @challenge_parts.length == 2

        logger.debug "Key authorization #{@challenge_parts.join('.')} is not well formed"
        false
      end

      def token_matches
        return true if @challenge_parts[0] == hmac_key

        logger.debug "Mismatching token in key authorization: #{parts[0]} instead of #{hmac_key}"
        false
      end

      def thumbprint_matches
        return true if @challenge_parts[1] == thumbprint

        logger.debug "Mismatching thumbprint in key authorization: #{@challenge_parts[1]} instead of #{thumbprint}"
        false
      end

      class_methods do
        def acme_verify(challenge)
          return false if hmac_key.blank? || thumbprint.blank?

          @challenge_parts = challenge.split('.')
          verified
        end

        def dcv_verify(protocol, options)
          begin
            Timeout.timeout(Surl::TIMEOUT_DURATION) do
              return self.class.cname_verify(options[:cname_origin], options[:cname_destination]) if protocol =~ /cname/

              response = case protocol
                         when /https/
                           self.class.https_verify(options[:https_dcv_url])
                         when /acme_http/
                           self.class.http_verify(options[:http_dcv_url])
                         when /acme_dns_txt/
                           raise 'Not Implemented'
                         else
                           self.class.http_verify(options[:http_dcv_url])
                         end
              return verify_challenge(response, options, protocol.match?(/acme/))
            end
          rescue StandardError => _e
            false
          end
        end

        def https_verify(https_dcv_url)
          uri = URI.parse(https_dcv_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          http.request(request).body
        end

        def cname_verify(cname_origin, cname_destination)
          txt = Resolv::DNS.open do |dns|
            dns.getresources(cname_origin, Resolv::DNS::Resource::IN::CNAME)
          end
          txt.size.positive? ? cname_destination.casecmp(txt.last.name.to_s).zero? : false
        end

        def http_verify(http_dcv_url)
          uri = URI.parse(http_dcv_url)
          response = uri.open('User-Agent' => I18n.t('users_agent.chrome'), redirect: true)
          response.read
        end
      end
    end
  end
end
