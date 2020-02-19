# frozen_string_literal: true

module Concerns
  module CertificateName
    module Verification
      extend ActiveSupport::Concern

      def dcv_verify(protocol = nil)
        case protocol ||= domain_control_validation.try(:dcv_method)
        when /email/
          nil
        when /acme_http/
          AcmeManager::HttpVerifier.new(api_credential, non_wildcard_name(true)).call
        when /acme_dns_txt/
          AcmeManager::DnsTxtVerifier.new(api_credential, non_wildcard_name(true)).call
        else
          prepend = ''
          self.class.dcv_verify(protocol,
                                https_dcv_url: dcv_url(true, prepend, true),
                                http_dcv_url: dcv_url(false, prepend, true),
                                cname_origin: cname_origin(true),
                                cname_destination: cname_destination,
                                csr: csr,
                                ca_tag: ca_tag)
        end
      end

      def verified(response, options)
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

      def api_credential
        certificate_content&.ssl_account&.api_credential
      end

      included do
        def self.dcv_verify(protocol, options)
          begin
            Timeout.timeout(Surl::TIMEOUT_DURATION) do
              response = self.class.selected_verification(protocol, options)

              return verified(response, options)
            end
          rescue StandardError => _e
            false
          end
        end

        def self.verify(protocol, options)
          case protocol
          when /https/
            self.class.https_verify(options[:https_dcv_url])
          when /cname/
            self.class.cname_verify(options[:cname_origin], options[:cname_destination])
          else
            self.class.http_verify(options[:http_dcv_url])
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
          txt.size.positive? ? cname_destination.casecmp(txt.last.name.to_s).zero? : false
        end

        def self.http_verify(http_dcv_url)
          uri = URI.parse(http_dcv_url)
          response = uri.open('User-Agent' => I18n.t('users_agent.chrome'), redirect: true)
          response.read
        end
      end
    end
  end
end
