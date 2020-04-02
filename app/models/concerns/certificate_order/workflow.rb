# frozen_string_literal: true

module Concerns
  module CertificateOrder
    module Workflow
      extend ActiveSupport::Concern

      included do
        workflow do
          state :new do
            event :pay, transitions_to: :paid do |payment|
              halt unless payment
              post_process_csr unless is_prepaid?
            end
            event :reject, transitions_to: :rejected
            event :cancel, transitions_to: :canceled
          end

          state :paid do
            event :cancel, transitions_to: :canceled
            event :reject, transitions_to: :rejected
            event :refund, transitions_to: :refunded
            event :charge_back, transitions_to: :charged_back
            event :start_over, transitions_to: :paid do |complete = false|
              if certificate_contents.count > 1
                cc = certificate_contents.last
                cc.preserve_certificate_contacts
                cc.delete
              else
                duration = certificate_content.duration
                temp_cc = certificate_contents.create(duration: duration)
                # Do not delete the last one
                (certificate_contents - [temp_cc]).each do |cc|
                  cc.delete if (cc.csr || cc.csr.try(:signed_certificate)) || complete
                end
              end
            end
          end

          state :canceled do
            event :uncancel, transitions_to: :paid
            event :unrefund, transitions_to: :canceled
            event :refund, transitions_to: :refunded
            event :reject, transitions_to: :rejected
            event :charge_back, transitions_to: :charged_back
            event :cancel, transitions_to: :canceled
          end

          state :refunded do # only refund a canceled order
            event :unrefund, transitions_to: :paid
            event :reject, transitions_to: :rejected
            event :charge_back, transitions_to: :charged_back
          end

          state :charged_back

          state :rejected do # only refund a canceled order
            event :cancel, transitions_to: :canceled
            event :unreject, transitions_to: :paid
            event :refund, transitions_to: :refunded
          end
        end
      end
    end
  end
end
