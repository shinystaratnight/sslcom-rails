module MailerHelper
  def email_body(first=nil)
    delivery(first).body.raw_source
  end

  def email_from(first=nil)
    delivery(first).from.first
  end

  def email_to(first=nil)
    delivery(first).to.first
  end

  def email_subject(first=nil)
    delivery(first).subject
  end

  def clear_email_deliveries
    ActionMailer::Base.deliveries.clear
  end

  def email_total_deliveries
    ActionMailer::Base.deliveries.count
  end

  private
    def delivery(first)
      deliveries = ActionMailer::Base.deliveries
      first ? deliveries.first : deliveries.last
    end
end
