# frozen_string_literal: true

module Concerns
  module User
    module Scope
      extend ActiveSupport::Concern

      included do
        default_scope { where.not(status: 'disabled').order('users.created_at desc') }
        scope :with_role, ->(role) { joins(:roles).where('lower(roles.name) LIKE (?)', "%#{role.downcase.strip}%") }
        scope :search,    lambda { |term|
                            joins{ ssl_accounts.api_credentials }.where do
                              (login =~ "%#{term}%") |
                                (email =~ "%#{term}%") |
                                (last_login_ip =~ "%#{term}%") |
                                (current_login_ip =~ "%#{term}%") |
                                (ssl_accounts.api_credentials.account_key =~ "%#{term}%") |
                                (ssl_accounts.api_credentials.secret_key =~ "%#{term}%") |
                                (ssl_accounts.acct_number =~ "%#{term}%")
                            end .uniq
                          }

        scope :search_sys_admin, -> { joins{ roles }.where{ roles.name == Role::SYSADMIN } }

        scope :search_super_user, -> { joins{ roles }.where{ roles.name == Role::SUPER_USER } }
      end
    end
  end
end
