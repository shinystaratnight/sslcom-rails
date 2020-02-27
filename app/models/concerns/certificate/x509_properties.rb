module Concerns
  module Certificate
    module X509Properties
      extend ActiveSupport::Concern

      def openssl_x509
        begin
          OpenSSL::X509::Certificate.new(body.strip)
        rescue Exception
        end
      end

      def issuer_dn
        openssl_x509.issuer.to_s(OpenSSL::X509::Name::RFC2253)
      end

      def dn
        openssl_x509.subject.to_s
      end

      def not_after
        openssl_x509.not_after
      end

    end
  end
end
