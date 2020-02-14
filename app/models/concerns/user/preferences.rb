# frozen_string_literal: true

module Concerns
  module User
    module Preferences
      extend ActiveSupport::Concern

      included do
        preference  :managed_certificate_row_count, :string, default: '10'
        preference  :registered_agent_row_count, :string, default: '10'
        preference  :cert_order_row_count, :string, default: '10'
        preference  :order_row_count, :string, default: '10'
        preference  :cdn_row_count, :string, default: '10'
        preference  :user_row_count, :string, default: '10'
        preference  :note_group_row_count, :string, default: '10'
        preference  :scan_log_row_count, :string, default: '10'
        preference  :domain_row_count, :string, default: '10'
        preference  :domain_csr_row_count, :string, default: '10'
        preference  :team_row_count, :string, default: '10'
        preference  :validate_row_count, :string, default: '10'
        preference  :managed_csr_row_count, :string, default: '10'
      end
    end
  end
end
