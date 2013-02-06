module CertificateOrdersHelper
  def order_line_items(certificate_order, email_template=false)
    items = []
    if certificate_order.certificate.is_ucc? ||
        certificate_order.certificate.is_wildcard?
      soi = certificate_order.sub_order_items.detect{|item|item.
          product_variant_item.is_server_license?}
      unless soi.blank?
        if certificate_order.created_at && certificate_order.created_at < DateTime.new(2013, 2, 6)
          items << pluralize(soi.quantity+1, "server license")
        end
        if certificate_order.certificate.is_ucc?
          soid = certificate_order.sub_order_items.find_all{|item|item.
              product_variant_item.is_domain?}
          quantity = soid.sum(&:quantity)
          unless certificate_order.certificate_contents.empty?
            d=certificate_order.certificate_content.domains
            domains = d.blank? ? "" : certificate_order.
              certificate_content.domains.join(", ")
            if email_template
              items << "domains - " +   (domains.empty? ? "" : "("+domains+")")
            else
              items << content_tag(:dt,pluralize(quantity, "domain")) +
                (domains.empty? ? "" : content_tag(:dd,"("+domains+")"))
            end
          end
        end
      end
    end
    unless certificate_order.migrated_from_v2?
      items << "SSL.com Secured Seal"
      items << "SSL.com daily site monitoring"
    end
    items
  end

  def check_for_current_certificate_order
    return false unless @certificate_order
  end

  def expires_on(certificate_content)
    (certificate_content.new? ||
        certificate_content.csr.signed_certificate.blank? ||
        certificate_content.csr.signed_certificate.expiration_date.blank?)?
      "n/a" : certificate_content.csr.signed_certificate.
        expiration_date.strftime("%b %d, %Y")
  end

  def action(certificate_order)
    certificate_content = certificate_order.certificate_content
    if certificate_content.new?
      certificate_order.expired? ? "n/a" :
          link_to('submit csr', edit_certificate_order_path(certificate_order))
    elsif certificate_order.expired?
      'n/a'
    else
      case certificate_content.workflow_state
        when "csr_submitted"
          link_to 'provide info',
            edit_certificate_order_path(certificate_order)
        when "info_provided"
          link_to 'provide contacts',
            certificate_content_contacts_url(certificate_content)
        when "reprocess_requested"
          link_to 'submit csr',
            edit_certificate_order_path(certificate_order)
        when "contacts_provided"
          link_to 'provide validation',
            new_certificate_order_validation_path(certificate_order)
        when "pending_validation", "validated"
          last_sent=certificate_order.csr.last_dcv
          if last_sent.blank?
            'please wait' #assume intranet
          elsif last_sent.try(:dcv_method)=="http"
            instructions="Please wait while we perform final validations.
            Normal process times should be less than several hours, but can take up to 24 hours. "
            instructions << "Also, be sure to leave #{certificate_order.certificate_content.csr.dcv_url}
            on the server until the certificate is issued." if certificate_content.preferred_reprocessing?
            link_to("please wait #{image_tag('question_mark.png', alt:
                "next step for certificate #{certificate_order.csr.common_name} (order# #{certificate_order.ref})")}".html_safe,
                    "#pp-#{certificate_order.ref}", :rel => 'prettyPhoto').html_safe+
            content_tag(:div, content_tag(:div, content_tag(:p, instructions), :class=>"pop_content"), id: "pp-#{certificate_order.ref}", class: "pop_container")
          else
            link_to("response needed #{image_tag('question_mark.png', alt:
                "next step for certificate #{certificate_order.csr.common_name} (order# #{certificate_order.ref})")}".html_safe,
                    "#pp-#{certificate_order.ref}", :rel => 'prettyPhoto').html_safe+
            content_tag(:div, render(partial: "certificate_orders/validation_pop", locals: {last_sent: last_sent}), id: "pp-#{certificate_order.ref}", class: "pop_container")
          end
        when "issued"
          if certificate_content.expiring?
            if certificate_order.renewal && certificate_order.renewal.paid?
              link_to 'see renewal', certificate_order_path(certificate_order.renewal)
            else
              link_to 'renew', renew_certificate_order_path(certificate_order)
            end
          else
            link_to 'reprocess', reprocess_certificate_order_path(certificate_order)
          end
        when "canceled"
      end
    end
  end

  def other_party_request(certificate_order)
    return true if current_user.blank?
    !(certificate_order.ssl_account==current_user.ssl_account)
  end

  def certificate_order_status(certificate_content=nil)
    return if certificate_content.blank?
    co=certificate_content.certificate_order
    if certificate_content.new?
      co.is_expired? ? 'expired' : 'waiting for csr'
    elsif certificate_content.expired? ||
        certificate_content.certificate_order.expired?
      'expired'
    elsif certificate_content.preferred_reprocessing?
      'reprocess requested'
    else
      case certificate_content.workflow_state
      when "csr_submitted"
        'info required'
      when "info_provided"
        'contacts required'
      when "reprocess_requested"
        'csr required'
      when "contacts_provided"
        'validation required'
      else
         certificate_content.workflow_state.to_s.titleize.downcase
      end
    end
  end

  def status_class(certificate_content)
    return 'attention' if certificate_content.new? ||
      certificate_content.expired?
    case certificate_content.workflow_state
      when "csr_submitted", "info_provided", "reprocess_requested",
          "contacts_provided"
        'attention'
      when "pending_validation"
        'validation_waiting'
      #give the green indicator. pondering on setting
      #validated to validation_waiting
      when "validated", "issued"
        'validation_approved'
      else
        ''
    end
  end

  def expires_on_class(certificate_content)
    return if certificate_content.new? ||
      certificate_content.csr.signed_certificate.blank? ||
      certificate_content.csr.signed_certificate.expiration_date.blank?
    sa = certificate_content.certificate_order.ssl_account
    ep = certificate_content.csr.signed_certificate.expiration_date
    if ep <= sa.preferred_reminder_notice_triggers(ReminderTrigger.find(1)).
        to_i.days.from_now && ep > Time.now
      'expiration_warning'
    elsif ep <= Time.now
      'attention'
    else
      ''
    end
  end

  def certificate_type(certificate_order)
    unless certificate_order.order.preferred_migrated_from_v2
      certificate_order.certificate.description["certificate_type"]
    else
      certificate_order.preferred_v2_product_description.
        gsub /[Cc]ertificate$/, ''
    end
  end
end
