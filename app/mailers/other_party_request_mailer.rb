class OtherPartyRequestMailer < ActionMailer::Base
  default :from => "SSL.com Certificate Services <support@ssl.com>"
  default_url_options[:host] = "www.ssl.com"

  def request_validation(emails, technical_contact, certificate_order)
    @to=emails
    @technical_contact = technical_contact
    @co=certificate_order
    subject = "SSL.com Certificate Request For Validation"
    mail(:to => @to, :subject => subject)
  end

  def confirmation(user)
    @to=user.email
    subject = "SSL Secure Lockbox Activated"
    @root_folder = url_for(user.ssl_account.root_folder)
    mail(:to => @to, :subject => subject)
  end

end

