module MailerHelper
  def email_body(position = nil)
    delivery(position).body.raw_source
  end

  def email_from(position = nil)
    delivery(position).from.first
  end

  def email_to(position = nil)
    delivery(position).to.first
  end

  def email_subject(position = nil)
    delivery(position).subject
  end

  def clear_email_deliveries
    ActionMailer::Base.deliveries.clear
  end

  def email_total_deliveries
    ActionMailer::Base.deliveries.count
  end

  def extract_url(str)
    urls   = URI.extract(str)
    ignore = ['Team:', 'Roles:', 'Note:']
    urls.delete_if{ |d| ignore.include?(d) }
    if urls.any?
      urls = urls.first
                 .gsub("http://#{Settings.portal_domain}", '')
                 .gsub(%r{https://127.0.0.1:\d+}, '')
    end
  end

  private

  def delivery(position)
    deliveries = ActionMailer::Base.deliveries
    if position
      position = position == :first ? 0 : position - 1
      deliveries[position]
    else
      deliveries.last
    end
  end
end
