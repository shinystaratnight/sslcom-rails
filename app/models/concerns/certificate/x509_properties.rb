module Concerns
  module Certificate
    module X509Properties
      extend ActiveSupport::Concern

      def openssl_x509
        OpenSSL::X509::Certificate.new(body.strip)
      end

      def issuer_dn
        openssl_x509.issuer.to_utf8
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
