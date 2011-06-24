class OtherPartyRequestMailer < ActionMailer::Base
  default :from => "SSL.com Certificate Services <support@ssl.com>"
  default_url_options[:host] = "www.ssl.com"

  def request_validation(other_party_validation_request)
    @opvr = other_party_validation_request
    @co = @opvr.other_party_requestable
    @to = @opvr.email_addresses.join(", ")
    @technical_contact =
      if @co.administrative_contact
        [@co.administrative_contact.first_name, @co.administrative_contact.last_name].join(" ")
      else
        "An SSL.com customer"
      end
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

