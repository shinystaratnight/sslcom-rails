# frozen_string_literal: true

module Concerns
  module CertificateName
    module Verification
      extend ActiveSupport::Concern

      def dcv_verify(protocol = nil)
        case protocol ||= domain_control_validation&.dcv_method
        when /email/
          nil
        when /acme_http/
          AcmeManager::HttpVerifier.new(api_credential.acme_acct_pub_key_thumbprint, acme_token, non_wildcard_name(true)).call
        when /acme_dns_txt/
          AcmeManager::DnsTxtVerifier.new(api_credential.acme_acct_pub_key_thumbprint, non_wildcard_name(true)).call
        else
          self.class.dcv_verify(protocol, verification_options)
        end
      end

      def verification_options(prepend = '')
        { https_dcv_url: dcv_url(true, prepend, true),
          http_dcv_url: dcv_url(false, prepend, true),
          cname_origin: cname_origin(true),
          cname_destination: cname_destination,
          csr: csr,
          ca_tag: ca_tag }
      end

      def api_credential
        certificate_content&.ssl_account&.api_credential
      end

      included do
        def self.dcv_verify(protocol, options)
          @options = options
          Timeout.timeout(Surl::TIMEOUT_DURATION) do
            @response = verify(protocol)
            case response
            when TrueClass, FalseClass
              response
            else
              verified
            end
          rescue StandardError => _e
            return false
          end
        end

        def self.options
          @options
        end

        def self.response
          @response
        end

        def self.verify(protocol)
          case protocol
          when /https/
            https_verify(options[:https_dcv_url])
          when /cname/
            cname_verify(options[:cname_origin], options[:cname_destination])
          else
            http_verify(options[:http_dcv_url])
          end
        end

        def self.https_verify(https_dcv_url)
          uri = URI.parse(https_dcv_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          http.request(request).body
        end

        def self.cname_verify(cname_origin, cname_destination)
          txt = Resolv::DNS.open do |dns|
            dns.getresources(cname_origin, Resolv::DNS::Resource::IN::CNAME)
          end
          txt&.size&.positive? ? cname_destination.casecmp(txt.last.name.to_s).zero? : false
        end

        def self.http_verify(http_dcv_url)
          uri = URI.parse(http_dcv_url)
          response = uri.open('User-Agent' => I18n.t('users_agent.chrome'), redirect: true)
          response.read
        end

        def self.verified
          !!(sha2_hash_matches? && ca_tag_valid? && unique_value_accepted?)
        end

        def self.ca_tag
          options[:ca_tag]
        end

        def self.csr
          options[:csr]
        end

        def self.has_ssl_ca_tag?
          ca_tag == I18n.t('labels.ssl_ca')
        end

        def self.sha2_hash_matches?
          response.match? Regexp.new("^#{options[:csr].sha2_hash}")
        end

        def self.unique_value_not_considered?
          csr.unique_value.blank? || options[:ignore_unique_value].presence || false
        end

        def self.unique_value_accepted?
          unique_value_not_considered? || unique_value_matches?
        end

        def self.unique_value_matches?
          response.match? Regexp.new("^#{options[:csr].unique_value}")
        end

        def self.ca_tag_valid?
          has_ssl_ca_tag? || has_matching_external_ca_tag?
        end

        def self.has_matching_external_ca_tag?
          response.match? Regexp.new("^#{options[:ca_tag]}")
        end

        def has_unique_value_from_csr?
          response.match? Regexp.new("^#{csr.unique_value}")
        end
      end
    end
  end
end
