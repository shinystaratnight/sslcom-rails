# frozen_string_literal: true

module AcmeManager
  class HttpVerifier < ApplicationService
    attr_reader :challenge_url, :api_credential, :parts

    def initialize(api_credential, challenge_url)
      @api_credential = api_credential
      @challenge_url = challenge_url
    end

    def call
      @parts = AcmeManager.get_challenge(challenge_path)
      verified
    end

    private

    def challenge_path
      "#{@challenge_url}/.well-known/acme-challenge/#{@api_credential.acme_acct_pub_key_thumbprint}"
    end

    def verified
      well_formed && token_matches && thumbprint_matches
    end

    def well_formed
      return true if @parts&.length == 2

      logger.debug "Key authorization #{@parts.join('.')} is not well formed"
      false
    end

    def token_matches
      return true if @parts[0] == hmac_key

      logger.debug "Mismatching token in key authorization: #{@parts[0]} instead of #{hmac_key}"
      false
    end

    def thumbprint_matches
      return true if @parts[1] == thumbprint

      logger.debug "Mismatching thumbprint in key authorization: #{@parts[1]} instead of #{thumbprint}"
      false
    end

    def hmac_key
      @api_credential.hmac_key
    end

    def thumbprint
      @api_credential.acme_acct_pub_key_thumbprint
    end
  end
end
