class DuplicateV2UserMailer < ActionMailer::Base
  default :from => "SSL.com Certificate Services <no-reply@ssl.com>"
  default_url_options[:host] = "www.ssl.com"

  def duplicate_found(dup)
    @to = @opvr.email_addresses.join(", ")
    @technical_contact =
      if @co.administrative_contact
        [@co.administrative_contact.first_name, @co.administrative_contact.last_name].join(" ")
      else
        "An SSL.com customer"
      end
    subject = "Duplicate login info found for #{dup.model_and_id}"
    mail(:to => @to, :subject => subject)
  end

  def attempted_login_by(dup)
    @dup=dup
    @to = Settings.notify_address
    subject = "SSL.com System Notification: login attempt by duplicate login"
    mail(:to => @to, :subject => subject)
  end

  def duplicates_found(dup, email_or_login)
    @dup, @email_or_login=dup, email_or_login
    @to = Settings.notify_address
    subject = "SSL.com System Notification: attempted reset of user with duplicate #{email_or_login}"
    mail(:to => @to, :subject => subject)
  end
end

