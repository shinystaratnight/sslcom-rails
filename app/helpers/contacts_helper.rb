module ContactsHelper
  def setup_certificate_contacts(certificate_content)
    returning(certificate_content) do |cc|
      if cc.certificate_contacts.empty?
        cc.billing_checkbox, cc.technical_checkbox, cc.validation_checkbox =
          true, true, true
        4.times do
          contact = cc.certificate_contacts.build
          contact.country = 'US'
        end
      end
    end
  end

  def render_contact_fields(c, role)
    if c.object.new_record?
      c.object.clear_roles
      c.object.add_role(role)
    end
    render '/contacts/certificate_contact', :f => c,
      :contact_role=>role
  end
end
