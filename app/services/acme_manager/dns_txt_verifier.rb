# frozen_string_literal: true

module AcmeManager
  class DnsTxtVerifier < ApplicationService
    attr_reader :challenge_url, :api_credential, :token

    def initialize(api_credential, challenge_url)
      @api_credential = api_credential
      @challenge_url = challenge_url
    end

    def call
      challenge
      verified
    end

    private

    def challenge
      @token = Resolv::DNS.open do |dns|
        dns.getresources(challenge_path, Resolv::DNS::Resource::IN::TXT)
      end
    end

    def challenge_path
      ['_acme-challenge', @challenge_url].join('.')
    end

    def verified
      well_formed && token_matches
    end

    def well_formed
      return true if @token.match?(/\w/)

      logger.debug "Key authorization #{@token} is not well formed"
      false
    end

    def token_matches
      return true if @token == thumbprint

      logger.debug "Mismatching token in key authorization: #{@token} instead of #{thumbprint}"
      false
    end

    def thumbprint
      @api_credential.acme_acct_pub_key_thumbprint
    end
  end
end
