# frozen_string_literal: true

module AcmeManager
  class HttpVerifier < ApplicationService
    rescue_from OpenURI::HTTPError do
      return false
    end
    attr_reader :challenge_url, :parts, :acme_token, :thumbprint

    def initialize(thumbprint, acme_token, challenge_url)
      @thumbprint = thumbprint
      @acme_toke = acme_token
      @challenge_url = challenge_url
    end

    def call
      @parts = challenge.split('.')
      verified
    end

    private

    def challenge
      uri = URI.parse(challenge_path)
      response = uri.open('User-Agent' => I18n.t('users_agent.chrome'), redirect: true)
      response.read
    rescue StandardError=> e
      e
    end

    def challenge_path
      ['http:/', challenge_url, '.well-known', 'acme-challenge', thumbprint].join('/')
    end

    def verified
      well_formed && token_matches && thumbprint_matches
    end

    def well_formed
      return true if parts&.length == 2

      logger.debug "Key authorization #{parts.join('.')} is not well formed"
      false
    end

    def token_matches
      return true if parts[0] == acme_token

      logger.debug "Mismatching token in key authorization: #{parts[0]} instead of #{acme_token}"
      false
    end

    def thumbprint_matches
      return true if parts[1] == thumbprint

      logger.debug "Mismatching thumbprint in key authorization: #{parts[1]} instead of #{thumbprint}"
      false
    end
  end
end
