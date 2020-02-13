# frozen_string_literal: true

module AcmeManager
  class << self
    def get_challenge(challenge_url)
      uri = URI.parse(challenge_url)
      response = uri.open('User-Agent' => I18n.t('users_agent.chrome'), redirect: true)
      response&.read&.split('.')
    end
  end
end
