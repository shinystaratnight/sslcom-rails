# frozen_string_literal: true

module AcmeManager
  class DnsTxtVerifier < ApplicationService
    attr_reader :challenge_url, :thumbprint, :token

    def initialize(thumbprint, challenge_url)
      @thumbprint = thumbprint
      @challenge_url = challenge_url
    end

    def call
      challenge
      verified
    end

    private

    def challenge
      txt = Resolv::DNS.open do |dns|
        dns.getresources(challenge_path, Resolv::DNS::Resource::IN::TXT)
      end
      @token = txt.strings.last
    end

    def challenge_path
      ['_acme-challenge', @challenge_url].join('.')
    end

    def verified
      token_matches
    end

    def token_matches
      return true if token == thumbprint

      logger.debug "Mismatching token in key authorization: #{token} instead of #{thumbprint}"
      false
    end
  end
end
