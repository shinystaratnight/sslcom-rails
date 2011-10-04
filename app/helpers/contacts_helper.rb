module ContactsHelper
  def setup_certificate_contacts(certificate_content)
    certificate_content.tap do |cc|
      if cc.certificate_contacts.empty?
        cc.billing_checkbox, cc.technical_checkbox, cc.validation_checkbox =
          true, true, true
#        4.times do
#          contact = cc.certificate_contacts.build
#          contact.country = 'US'
#        end
      end
    end
  end

  def render_contact_fields(c, role)
    render '/contacts/certificate_contact', :f => c,
      :contact_role=>role
  end
end
