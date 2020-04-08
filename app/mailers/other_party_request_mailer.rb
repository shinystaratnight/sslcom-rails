class OtherPartyRequestMailer < ApplicationMailer
  default from: 'SSL.com Certificate Services <support@ssl.com>'

  def request_validation(other_party_validation_request)
    @opvr = other_party_validation_request
    @co = @opvr.other_party_requestable
    @to = @opvr.email_addresses.join(', ')
    @technical_contact =
      if @co.administrative_contact
        [@co.administrative_contact.first_name, @co.administrative_contact.last_name].join(' ')
      else
        'An SSL.com customer'
      end
    subject = "Validation Request for SSL.com Certificate #{@co.subject}" + (@opvr.preferred_show_order_number? ? " (Order Number #{@co.ref})" : '')
    mail(to: @to, subject: subject)
  end
end
