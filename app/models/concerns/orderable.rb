# frozen_string_literal: true

module Orderable
  extend ActiveSupport::Concern

  included do
    CSR_SUBMITTED = :csr_submitted
    INFO_PROVIDED = :info_provided
    REPROCESS_REQUESTED = :reprocess_requested
    CONTACTS_PROVIDED = :contacts_provided
    RENEWING = 'renewing'
    REPROCESSING = 'reprocessing'
    RECERTS = [RENEWING, REPROCESSING].freeze
    RENEWAL_DATE_CUTOFF = 45.days.ago
    RENEWAL_DATE_RANGE = 45.days.from_now

    STATUS = { CSR_SUBMITTED => 'info required',
               INFO_PROVIDED => 'contacts required',
               REPROCESS_REQUESTED => 'csr required',
               CONTACTS_PROVIDED => 'validation required' }.freeze

    acts_as_sellable cents: :amount, currency: false

    scope :not_new, lambda { |options = nil|
      includes = method(:includes).call(options[:includes]) if options && options.key?(:includes)
      (includes || self).where{ workflow_state << ['new'] }.uniq
    }

    scope :is_new, -> { where{ workflow_state >> ['new'] }.uniq }

    scope :nonfree, ->{ not_new.where(:amount.gt => 0) }

    scope :range, lambda{ |start, finish|
      if start.is_a?(String)
        (s = start =~ %r{/} ? '%m/%d/%Y' : '%m-%d-%Y')
        start = Date.strptime(start, s)
      end
      if finish.is_a?(String)
        (f = finish =~ %r{/} ? '%m/%d/%Y' : '%m-%d-%Y')
        finish = Date.strptime(finish, f)
      end
      where{ created_at >> (start..finish) }
    } do
      def amount
        nonfree.sum(:amount) * 0.01
      end
    end

    # Resets this order as if it never processed
    #   <tt>complete</tt> - removes the certificate_content (and it's csr and other properties)
    #   <tt>ext_ca_orders</tt> - removes the external calls history to comodo for this order
    def reset(complete = false, ext_ca_orders = false)
      reset_ext_ca_order if ext_ca_orders
      certificate_content&.csr&.delete

      start_over!(complete) unless %w[canceled revoked].include?(certificate_content.workflow_state)
    end

    # Creates a new external ca order history by deleting the old external order id and requests thus allowing us
    # to start a new history with comodo for an existing ssl.com cert order
    # useful in the event Comodo take forever to make changes to an existing order (and sometimes cannot) so we
    # just create a new one and have the old one refunded
    def reset_ext_ca_order
      csrs.compact.map(&:sent_success).flatten.uniq.each(&:delete)
      certificate_content.update_attribute(preferred_reprocessing: false)
    end

    def to_param
      ref
    end

    def clone_for_renew(certificate_orders, order)
      certificate_orders.each do |cert|
        cert.quantity.times do |i|
          # could use cert.dup after >=3.1, but we are currently on 3.0.10 so we'll do this manually
          new_cert = cert.dup
          cert.sub_order_items.each do |soi|
            new_cert.sub_order_items << soi.dup
          end
          if cert.migrated_from_v2?
            pvg = new_cert.sub_order_items[0].product_variant_item.product_variant_group
            pvg.update(variantable: cert.renewal_certificate)
          end
          new_cert.line_item_qty = cert.quantity if i == cert.quantity - 1
          new_cert.update(preferred_payment_order: 'prepaid')
          CertificateContent.create(certificate_order: new_cert)
          order.line_items.build sellable: new_cert
        end
      end
    end
  end
end
