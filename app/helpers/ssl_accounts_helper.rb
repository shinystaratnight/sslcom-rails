module SslAccountsHelper
  def cert_recipients_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        get(:preferred_processed_certificate_recipients).blank?
    end
  end
  def reminder_emails_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        get(:preferred_reminder_notice_destinations).blank?
    end
  end
  def receipt_emails_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        get(:preferred_receipt_recipients).blank?
    end
  end
  def confirmation_emails_errors
    "".tap do |result|
      result << 'fieldWithErrors' unless @ssl_account.errors.
        get(:preferred_confirmation_recipients).blank?
    end
  end
  def reminder_trigger_errors(rnt)
    "".tap do |result|
      result << 'fieldWithErrors' unless SslAccount::TRIGGER_RANGE.
        include?(rnt.to_i) && rnt=~/\d+/ || rnt.blank?
    end
  end

  def reseller_fields(target_team)
    reseller_fields = []

    unless target_team.reseller.blank?
      reseller_fields << "reseller_tier=#{target_team.reseller.reseller_tier_id}"
      reseller_fields << "first_name=#{target_team.reseller.first_name}"
      reseller_fields << "last_name=#{target_team.reseller.last_name}"
      reseller_fields << "email=#{target_team.reseller.email}"
      reseller_fields << "phone=#{target_team.reseller.phone}"
      reseller_fields << "type_organization=#{target_team.reseller.type_organization}"
      reseller_fields << "organization=#{target_team.reseller.organization}"
      reseller_fields << "website=#{target_team.reseller.website}"
      reseller_fields << "address1=#{target_team.reseller.address1}"
      reseller_fields << "postal_code=#{target_team.reseller.postal_code}"
      reseller_fields << "city=#{target_team.reseller.city}"
      reseller_fields << "state=#{target_team.reseller.state}"
      reseller_fields << "tax_number=#{target_team.reseller.tax_number}"
      reseller_fields << "country=#{target_team.reseller.country}"
    end

    reseller_fields.map{|d|d.gsub(/\\/,'\\\\').gsub(',','\,')}.join(",")
  end
end
