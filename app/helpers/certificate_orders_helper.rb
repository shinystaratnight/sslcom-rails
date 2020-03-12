module CertificateOrdersHelper

  def render_certificate_durations
    certificate_id = params[:certificate_id] || params[:certificate_enrollment_invite][:certificate_id]
    @certificate = Certificate.find certificate_id
    partial = render_to_string(
      partial: 'certificate_orders/smime_client_enrollment/duration_form',
      layout: false
    )
    render json: {content: partial}, status: :ok
  end

  def order_line_items(certificate_order, email_template=false, invoice=false)
    items = []
    if certificate_order.certificate.is_ucc? || certificate_order.certificate.is_wildcard?
      soi = certificate_order.sub_order_items.detect{|item|item.
          product_variant_item.is_server_license?}
      unless soi.blank?
        if soi.quantity>0
          items << pluralize(soi.quantity+1, "server license")
        end
        if certificate_order.certificate.is_ucc?
          reprocess_order    = @order && @order.reprocess_ucc_order?
          domains_adjustment = @order && @order.domains_adjustment? && !reprocess_order
          reprocess_domains  = @order.get_reprocess_domains if (reprocess_order || domains_adjustment)

          quantity = (domains_adjustment || reprocess_order) ? reprocess_domains[:all].count : certificate_order.purchased_domains('all')
          unless certificate_order.certificate_contents.empty?
            d            = reprocess_order ? reprocess_domains[:all] : certificate_order.all_domains
            domains      = d.blank? ? "" : d.join(", ")
            wildcard_qty = reprocess_order ? reprocess_domains[:cur_wildcard] : certificate_order.purchased_domains('wildcard')

            if email_template
              items << "domains - " +   (domains.empty? ? "" : "("+domains+")")
            elsif invoice
              items << pluralize(quantity, "#{certificate_order.certificate.is_premium_ssl? ? 'sub' : ''}domain") +
                (wildcard_qty==0 ? '' : " (#{pluralize(wildcard_qty, 'wildcard ssl domain')})")
              items << domains.split('+') unless domains.empty? || domains.blank?
            else
              items << content_tag(:dt,pluralize(quantity, "#{certificate_order.certificate.is_premium_ssl? ? 'sub' : ''}domain")+
                (wildcard_qty==0 ? '' : " (#{pluralize(wildcard_qty, 'wildcard ssl domain')})")) +
                (domains.empty? ? "" : content_tag(:dd,"("+domains+")"))
            end

            if (reprocess_order && reprocess_domains[:new_domains_count] > 0) || domains_adjustment
              co_desc = invoice ? " For certificate order ##{certificate_order.ref}." : ''
              descr = if @order.invoice_description.blank?
                "Prorated charge for #{reprocess_domains[:new_domains_count]}
                additional domains. (wildcard: #{reprocess_domains[:wildcard]},
                non wildcard: #{reprocess_domains[:non_wildcard]})"
              else
                "#{@order.invoice_description} #{co_desc}"
              end
              items << content_tag(:strong, descr)
            end
          end
        end
      end
    end
    if !(certificate_order.certificate.is_client? || certificate_order.certificate.is_code_signing?)
      items << "SSL.com Secured Seal"
      items << link_to("SSL.com daily site monitoring", notification_groups_path({ssl_slug: @ssl_slug}))
    end
    items
  end

  def check_for_current_certificate_order
    return false unless @certificate_order
  end

  def expires_on(certificate_content)
    return "n/a" if certificate_content.csr.blank?
    (certificate_content.new? ||
        certificate_content.csr.signed_certificate.blank? ||
        certificate_content.csr.signed_certificate.expiration_date.blank?)?
      "n/a" : certificate_content.csr.signed_certificate.
        expiration_date.strftime("%b %d, %Y")
  end

  def sandbox_notice
    flash[:sandbox] = "SSL.com Sandbox. This is a test environment for api orders. Transactions and orders are not live."
  end

  def domains_adjust_billing?(certificate_order)
    return false if certificate_order.nil? || certificate_order.new?
    certificate_order.domains_adjust_billing?
  end

  def action(certificate_order)
    certificate_content = certificate_order.certificate_contents.last
    certificate = certificate_order.certificate
    if certificate_content.new?
      certificate_order.expired? ? "expired" :
          link_to(certificate_order.certificate.admin_submit_csr?  ? 'provide info' :
                      'submit csr', edit_certificate_order_path(@ssl_slug, certificate_order))
    elsif certificate_order.expired?
      link_to 'renew', renew_certificate_order_path(@ssl_slug, certificate_order)
    else
      case certificate_content.workflow_state
      when "csr_submitted"
        link_to('provide info', edit_certificate_order_path(@ssl_slug, certificate_order)) if
            permitted_to?(:update, certificate_order)
      when "info_provided"
        link_to('provide contacts', certificate_content_contacts_path(@ssl_slug, certificate_content)) if
            permitted_to?(:update, certificate_order)
      when "reprocess_requested"
        link_to('submit csr', edit_certificate_order_path(@ssl_slug, certificate_order)) if
            permitted_to?(:update, certificate_order)
      when "contacts_provided", "pending_validation", "validated"
        if certificate_content.workflow_state == "validated" && (certificate.is_cs? || certificate.is_smime_or_client?)
          specific_action(certificate, certificate_order, false)
          # link_to 'generate certificate', generate_cert_certificate_order_path(@ssl_slug, certificate_order.ref) if
          #     permitted_to?(:update, certificate_order.validation) # assume multi domain
        else
          link_to certificate_order.certificate.admin_submit_csr? ? 'upload documents' : 'perform validation', new_certificate_order_validation_path(@ssl_slug, certificate_order) if
              permitted_to?(:update, certificate_order.validation) # assume multi domain
        end
      when "issued","revoked"
        if(certificate.is_cs? || certificate.is_smime_or_client?)
          specific_action(certificate, certificate_order, true)
          # link_to 'generate certificate', generate_cert_certificate_order_path(@ssl_slug, certificate_order.ref) if
          #     permitted_to?(:update, certificate_order.validation) # assume multi domain
        else
          if certificate_content.expiring?
            if certificate_order.renewal && certificate_order.renewal.paid?
              link_to('see renewal', certificate_order_path(@ssl_slug, certificate_order.renewal)) if
                  permitted_to?(:show, certificate_order)
            elsif certificate_order.signed_certificate_duration_delta > 1
              link_to('change domain(s)/rekey', reprocess_certificate_order_path(@ssl_slug,
                  certificate_order)) if permitted_to?(:update, certificate_order)
            else
              links =  "<li>#{link_to 'renew', renew_certificate_order_path(@ssl_slug, certificate_order)}</li>"
              links << "<li> or #{link_to 'change domain(s)/rekey', reprocess_certificate_order_path(@ssl_slug,
                  certificate_order)}</li>" if permitted_to?(:update, certificate_order) and
                  !certificate_content.expired?
              "<ul>#{links}</ul>".html_safe
            end
          else
            if certificate_order.certificate.is_free?
              links =  "<li>#{link_to 'upgrade', renew_certificate_order_path(@ssl_slug, certificate_order)}</li>"
              links << "<li>or #{link_to 'change domain(s)/rekey',
                   reprocess_certificate_order_path(@ssl_slug, certificate_order)}</li>" if permitted_to?(:update,
                  certificate_order) and !certificate_content.expired?
              "<ul>#{links}</ul>".html_safe
            else
              ("<ul>"+(current_page?(certificate_order_path(@ssl_slug, certificate_order)) ? "" :
                           "<li>#{link_to 'download', certificate_order_path(@ssl_slug, certificate_order)} or </li>")+
                  ((permitted_to?(:read, certificate_order) and !certificate_content.expired?) ?
                       "<li>#{link_to 'change domain(s)/rekey',
                                      reprocess_certificate_order_path(@ssl_slug, certificate_order)}</li></ul>" : "")).html_safe

            end
          end
        end
      when "canceled"
      end
    end
  end

  def specific_action(certificate, certificate_order, is_rekey)
    if current_user.is_individual_certificate? or
        (certificate_order.get_recipient and certificate_order.get_recipient.email==current_user.email)
      reset_expired_token_request_status(certificate_order)

      if certificate_order.generate_certificate_order_token.blank? or certificate_order.generate_certificate_order_token.is_expired
        if certificate.is_client_basic?
          recipient = certificate_order.get_recipient
          iv = Contact.find_by(user_id: (recipient.user_id || recipient.id))
          certificate_order.update_attribute(:request_status, 'done')

          link_to 'send activation link to ' + iv.email,
                  nil, class: 'link_to_send_notify',
                  :data => { :ref => certificate_order.ref,
                             :type => 'token',
                             :ori_text => '',
                             :done => 'false'
                  }
        else
          link_to certificate_order.request_status == 'done' ? 'activation request sent. Request again?' : (is_rekey ? 'request rekey' : 'request certificate'),
                  nil, class: 'link_to_send_notify',
                  :data => {
                      :ref => certificate_order.ref,
                      :type => 'request',
                      :done => certificate_order.request_status == 'done' ? 'true' : 'false'
                  }
        end
      else
        if !certificate.is_client_basic? || (certificate.is_client_basic? && current_user.is_standard? && current_user.ssl_account.epki_registrant)
          link_to 'generate certificate', confirm_path(certificate_order.generate_certificate_order_token.token) if
              permitted_to?(:update, certificate_order.validation) # assume multi domain
        else
          recipient = certificate_order.get_recipient
          iv = Contact.find_by(user_id: (recipient.user_id || recipient.id))

          link_to 'activation link sent. Resend?',
                  nil, class: 'link_to_send_notify',
                  :data => { :ref => certificate_order.ref,
                             :type => 'token',
                             :ori_text => 'send activation link to ' + iv.email,
                             :done => 'true'
                  }
        end
      end
    elsif current_user.is_billing_only? || current_user.is_validations_only? || current_user.is_validations_and_billing_only?
      'n/a'
    else
      if certificate.is_smime_or_client? && certificate_order.get_recipient
        reset_expired_token_request_status(certificate_order)

        recipient = certificate_order.get_recipient
        iv = Contact.find_by(user_id: (recipient.user_id || recipient.id))
        link_to !certificate_order.generate_certificate_order_token.blank? && !certificate_order.generate_certificate_order_token.is_expired ?
                    'activation link sent. Resend?' : 'send activation link to ' + iv.email,
                nil, class: 'link_to_send_notify',
                :data => { :ref => certificate_order.ref,
                           :type => 'token',
                           :ori_text => ((!certificate_order.generate_certificate_order_token.blank? && !certificate_order.generate_certificate_order_token.is_expired) ?
                                             ('send activation link to ' + iv.email) : ''),
                           :done => (!certificate_order.generate_certificate_order_token.blank? && !certificate_order.generate_certificate_order_token.is_expired).to_s
                }
      elsif certificate_order.locked_registrant and certificate_order.certificate_content.ca
        reset_expired_token_request_status(certificate_order)

        link_to !certificate_order.generate_certificate_order_token.blank? && !certificate_order.generate_certificate_order_token.is_expired ?
                    'activation link sent. Resend?' : 'send activation link to ' + certificate_order.locked_registrant.email,
                nil, class: 'link_to_send_notify',
                :data => { :ref => certificate_order.ref,
                           :type => 'token',
                           :ori_text => ((!certificate_order.generate_certificate_order_token.blank? && !certificate_order.generate_certificate_order_token.is_expired) ?
                                             ('send activation link to ' + certificate_order.locked_registrant.email) : ''),
                           :done => (!certificate_order.generate_certificate_order_token.blank? && !certificate_order.generate_certificate_order_token.is_expired).to_s
                }
      else
        'n/a'
      end
    end
  end

  def reset_expired_token_request_status(certificate_order)
    if certificate_order.generate_certificate_order_token &&
        !certificate_order.generate_certificate_order_token.is_expired &&
        certificate_order.generate_certificate_order_token.due_date < DateTime.now
      certificate_order.generate_certificate_order_token.update_attribute(:is_expired, true)
      certificate_order.update_attribute(:request_status, '')
    end
  end

  def other_party_request(certificate_order)
    if current_user.blank?
      return true
    elsif current_user.is_admin?
      return false
    end
    (certificate_order.ssl_account!=current_user.ssl_account)
  end

  def certificate_order_status(certificate_content=nil,co=nil)
    return if certificate_content.blank?
    co ||= certificate_content.cached_certificate_order
    if co && certificate_content.new?
      co.is_expired? ? 'expired' : (co.certificate.admin_submit_csr? ? 'info required' : 'waiting for csr')
    elsif certificate_content.expired?
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
      when "validated", "issued", "pending_issuance"
        'validation_approved'
      else
        ''
    end
  end

  def expires_on_class(certificate_content,co=nil)
    return if certificate_content.new? ||
        certificate_content.csr.blank? ||
      certificate_content.csr.signed_certificate.blank? ||
      certificate_content.csr.signed_certificate.expiration_date.blank?
    co ||= certificate_content.cached_certificate_order
    if co.try(:ssl_account)
      sa = co.ssl_account
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
  end

  def certificate_type(certificate_order)
    extract=->{
      if certificate_order.is_a?(CertificateOrder)
        unless Order.unscoped{certificate_order.order}.preferred_migrated_from_v2
          certificate_order.certificate.description["certificate_type"]
        else
          certificate_order.preferred_v2_product_description.
              gsub /[Cc]ertificate\z/, ''
        end
      end
    }
    if certificate_order.new_record?
      extract.call
    else
      Rails.cache.fetch("#{certificate_order.cache_key}/certificate_type") do
        extract.call
      end
    end
  end

  def certificate_formats(csr, sc)
    if sc.is_smime_or_client? or sc.is_code_signing?
      {other: ["Individual certificates", download_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::OTHER_INSTALL_LINK],
       nginx: ["Single bundle", nginx_csr_signed_certificate_url(@ssl_slug, csr, sc), nil],
       iis7:  ["p7b format", pkcs7_csr_signed_certificate_url(@ssl_slug, csr, sc), nil]}
    else
      {iis7: ["Microsoft IIS (*.p7b)", pkcs7_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::IIS_INSTALL_LINK],
       cpanel: ["WHM/cpanel", whm_zip_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::CPANEL_INSTALL_LINK],
       apache: ["Apache", apache_zip_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::APACHE_INSTALL_LINK],
       amazon: ["Amazon", amazon_zip_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::AMAZON_INSTALL_LINK],
       nginx: ["Nginx", nginx_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::NGINX_INSTALL_LINK],
       v8_nodejs: ["V8+Node.js", nginx_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::V8_NODEJS_INSTALL_LINK],
       java: ["Java/Tomcat", download_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::JAVA_INSTALL_LINK],
       other: ["Other platforms", download_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::OTHER_INSTALL_LINK],
       bundle: ["CA bundle (intermediate certs)", server_bundle_csr_signed_certificate_url(@ssl_slug, csr, sc), SignedCertificate::OTHER_INSTALL_LINK]}
    end
  end

  def cs_certificate_formats(cc, pkc)
    {iis7: ["Microsoft IIS (*.p7b)", pkcs7_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::IIS_INSTALL_LINK],
     cpanel: ["WHM/cpanel", whm_zip_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::CPANEL_INSTALL_LINK],
     apache: ["Apache", apache_zip_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::APACHE_INSTALL_LINK],
     amazon: ["Amazon", amazon_zip_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::AMAZON_INSTALL_LINK],
     nginx: ["Nginx", nginx_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::NGINX_INSTALL_LINK],
     v8_nodejs: ["V8+Node.js", nginx_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::V8_NODEJS_INSTALL_LINK],
     java: ["Java/Tomcat", download_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::JAVA_INSTALL_LINK],
     other: ["Other platforms", download_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::OTHER_INSTALL_LINK],
     bundle: ["CA bundle (intermediate certs)", server_bundle_certificate_content_attestation_certificate_url(@ssl_slug, cc, pkc), SignedCertificate::OTHER_INSTALL_LINK]}
  end

  # When validation instructions are generated for a certificate name,
  # remove "www" for Basic SSL, High Assurance SSL, and Enterprise EV SSL certs
  # in the CN of the CSR
  def render_domain_for_instructions(certificate_order, target_domain)
    unless certificate_order.certificate.is_multi?
      target_domain = target_domain.remove(/\Awww./)
    end
    target_domain
  end

  def for_ev?
    @certificate_order.certificate.is_ev? unless ["ov","dv"].include?(params[:downstep])
  end

  # EV SSL can downstep to OV
  def for_ov?
    ((@certificate_order.certificate.is_ov? or @certificate_order.certificate.is_naesb?) unless ["dv"].
        include?(params[:downstep])) or downstepped_to_ov?
  end

  # EV and OV SSL can downstep to DV
  def for_dv?
    @certificate_order.certificate.is_dv? or downstepped_to_dv?
  end

  def downstepped_to_dv?
    (@certificate_order.certificate.is_ev? or
        @certificate_order.certificate.is_ov?) and params[:downstep]=="dv"
  end

  def downstepped_to_ov?
    @certificate_order.certificate.is_ev? and params[:downstep]=="ov"
  end

  def downstepped_to_cs?
    @certificate_order.certificate.is_evcs? and params[:downstep]=="cs"
  end

  def downstepped?
    downstepped_to_cs? or downstepped_to_dv? or downstepped_to_ov?
  end

  def for_evcs?
    @certificate_order.certificate.is_evcs? unless ["cs"].include?(params[:downstep])
  end

  # EV CS can downstep to CS
  def for_cs?
    @certificate_order.certificate.is_cs? or downstepped_to_cs?
  end

  def show_management_key?(token)
    token.model_number == 'Yubikey FIPS 140-2' &&
      (for_evcs? || @certificate_order.certificate.is_client_business?)
  end
end
