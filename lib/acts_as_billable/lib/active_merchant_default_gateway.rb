module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Base
      @@default_gateway = :bogus
      @@default_gateway_options = {}
      
      # set the default gateway and options
      #
      #   ActiveMerchant::Billing::Base.set_default_gateway :bogus
      #
      #   ActiveMerchant::Billing::Base.set_default_gateway :paypal, :login => 'fred', :password => 'flintstone'
      def self.set_default_gateway(gateway, options = {})
        @@default_gateway = gateway
        @@default_gateway_options = options
      end
      
      # Get an instance of the default gateway
      def self.default_gateway
        ActiveMerchant::Billing::Base.gateway(@@default_gateway).new(@@default_gateway_options)
      end
    end
  end
end