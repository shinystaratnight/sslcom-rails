module ContactsHelper
  def setup_certificate_contacts(certificate_content)
    certificate_content.tap do |cc|
      if cc.certificate_contacts.empty?
        cc.billing_checkbox, cc.technical_checkbox, cc.validation_checkbox =
          true, true, true
      end
    end
  end

  def render_contact_fields(c, role)
    render '/contacts/certificate_contact', :f => c,
      :contact_role=>role
  end
  
  def render_saved_contacts(list)
    list.inject([]) do |contacts, c|
      main_info = {}
      full_name = "#{c.last_name}, #{c.first_name}"
      company   = c.company_name
      remove    = %w{id notes type roles contactable_id contactable_type created_at updated_at registrant_type}
      c.attributes.each {|key, val| main_info["data-#{key}"] = val}
      main_info = main_info.delete_if {|k,v| remove.include?(k.remove 'data-')}
      option = if c.type == 'Registrant'
        c.individual? ? "#{full_name} (individual)" : "#{company} (organization)"
      else
        [full_name, company].join(' | ')
      end
      contacts << [option, c.id, main_info]
      contacts.sort
    end
  end
end
