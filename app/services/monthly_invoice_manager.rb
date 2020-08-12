# frozen_string_liter: false

class MonthlyInvoiceManager

  def self.auto_charges(date_execute = Date.yesterday)
    MonthlyInvoice.pending.where(end_date: date_execute.beginning_of_day..date_execute.end_of_date).each do |monthly_invoice|
      MonthlyInvoiceManager.new(monthly_invoice).charging
    end
  end

  attr_reader :invoice, :ssl_account, :target_amount

  def intialize(invoice)
    @invoice = invoice
    @ssl_account = invoice.billable
    @target_amount = 0
  end

  def charging
    invoice.get_approved_items.each do |order|
      order.cerfificate_orders.each do |cert_order|
        target_amount += cert_order.amount if cert_order.signed_certificates.present?
      end
    end

    process_payment

  end

  private

  def order_invoice_notes
    "Payment for #{invoice.get_type_format.downcase} invoice total of #{invoice.get_amount_format} due on #{invoice.end_date.strftime('%F')}."
  end

  def process_payment
    return if target_amount == 0

    order = Order.new(
      amount:             target_amount,
      cents:              (target_amount * 100).to_i,
      description:        ssl_account.get_invoice_pmt_description,
      state:              'pending',
      approval:           'approved',
      notes:              order_invoice_notes
    )
    order.billable = ssl_accoun

    return order if ENV['TEST_MODE_MONTHLY_CHARGED']

    funded_account = ssl_account.funded_account
    funded_account.cents -= order.cents

    if funded_account.cents >= 0
      Authorization::Maintenance::without_access_control do
        if order.save
          funded_account.save
          update_invoice_status_and_notify_charged(order)
        end
      end
    elsif billing_profile = ssl_account.billing_profiles.where(default_profile: true).first
      order.billing_profile = billing_profile
      credit_card = billing_profile.build_credit_card

      options = billing_profile.build_info(order_invoice_notes)
      gateway_response = order.purchase(credit_card, options)
      (gateway_response.success?).tap do |success|
        if success
          order.mark_paid!
          order.save
          update_invoice_status_and_notify_charged(order)
        end
      end
    end
  end

  def update_invoice_status_and_notify_charged(order)
    invoice.update(order_id: order.id, status: 'paid')
    invoice.notify_invoice_paid(ssl_account.primary_user) if Settings.invoice_notify
  end
end
