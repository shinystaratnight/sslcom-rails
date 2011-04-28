module SslAccountsHelper
  def cert_recipients_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        on(:preferred_processed_certificate_recipients).blank?
    end
  end
  def reminder_emails_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        on(:preferred_reminder_notice_destinations).blank?
    end
  end
  def receipt_emails_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        on(:preferred_receipt_recipients).blank?
    end
  end
  def confirmation_emails_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        on(:preferred_confirmation_recipients).blank?
    end
  end
  def reminder_trigger_errors(rnt)
    "".tap do |result|
      result << 'fieldWithErrors' unless SslAccount::TRIGGER_RANGE.
        include?(rnt.to_i) && rnt=~/\d+/ || rnt.blank?
    end
  end
end
