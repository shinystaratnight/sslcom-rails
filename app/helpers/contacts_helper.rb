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
  
  def render_saved_registrants(list, with_data=nil)
    list.inject([]) do |registrants, r|
      main_info = {}
      remove = %w{id notes type contactable_id contactable_type created_at updated_at}
      final = r.attributes.merge('status' => r.status)
      final.each {|key, val| main_info["#{with_data ? 'data-' : ''}#{key}"] = val}
      main_info = main_info.delete_if {|k,v| remove.include?(k.remove 'data-')}
      option = "#{r.company_name} (#{r.status ? r.status.humanize : 'N/A'})"
      registrants << [option, r.id, main_info]
      registrants.sort
    end
  end

  def render_saved_contacts(list, with_data=nil)
    list.inject([]) do |contacts, c|
      main_info = {}
      recipient = c.type == 'IndividualValidation'
      full_name = "#{c.last_name}, #{c.first_name}"
      company   = c.company_name
      remove    = %w{id notes type contactable_id contactable_type created_at updated_at}
      c.attributes.each do |key, val|
        cur_val = (recipient && (key == 'status')) ? c.status : val
        main_info["#{with_data ? 'data-' : ''}#{key}"] = cur_val
      end
      main_info = main_info.delete_if {|k,v| remove.include?(k.remove 'data-')}
      option = if c.type == 'Registrant'
        c.individual? ? "#{full_name} (individual)" : "#{company} (organization)"
      elsif recipient
        [full_name, c.email].join(' | ')
      else
        [full_name, company].join(' | ')
      end
      contacts << [option, c.id, main_info]
      contacts.sort
    end
  end
end
