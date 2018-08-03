class OrderNotifier < ActionMailer::Base
  helper :application
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  helper CertificateOrdersHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods

  def test
    p caller[0] =~ /`([^']*)'/ and $1
  end
  alias_method :something, :test

  def order_transferred(params)
    @order_list = params[:orders_list]
    @co_list    = params[:co_list]
    @user       = params[:user].email
    @from_team  = params[:from_sa]
    @to_team    = params[:to_sa]
    @from_owner = @from_team.get_account_owner.email
    @to_owner   = @to_team.get_account_owner.email

    mail  subject: "Order(s) have been transferred from team #{@from_team.get_team_name} to team #{@to_team.get_team_name}.",
          from:    Settings.from_email.orders,
          to:      [@from_owner, @to_owner].uniq
  end
  
  def domains_adjustment_new(params)
    @user  = params[:user]
    @order = params[:order]
    @team  = @order.billable
    
    mail  subject: "A new domains adjustment order has been placed for team #{@team.get_team_name}.",
          from:    Settings.from_email.orders,
          to:      @user.email
  end
  
  def payable_invoice_new(params)
    @user    = params[:user]
    @invoice = params[:invoice]
    @team    = @invoice.billable
    @invoice_type = @invoice.get_type_format.downcase
    
    mail  subject: "You have a new #{@invoice_type} invoice for team #{@team.get_team_name}.",
          from:    Settings.from_email.orders,
          to:      @user.email
  end
  
  def payable_invoice_paid(params)
    @user    = params[:user]
    @paid_by = params[:paid_by]
    @invoice = params[:invoice]
    @team    = @invoice.billable
    @invoice_type = @invoice.get_type_format.downcase
    
    mail  subject: "Payment has been submitted for #{@invoice_type} invoice ##{@invoice.reference_number} for team #{@team.get_team_name}.",
          from:    Settings.from_email.orders,
          to:      @user.email
  end
  
  def reseller_certificate_order_paid(ssl_account, certificate_order)
    @ssl_account        = ssl_account
    @certificate_order  = certificate_order.reload
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate Confirmation For #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from:          Settings.from_email.orders,
          to:    certificate_order.valid_recipients_list

  end

  def certificate_order_prepaid(ssl_account, order)
    @ssl_account  = ssl_account
    @order        = order
    mail  subject: "SSL.com Confirmation for Order ##{order.reference_number}",
          from: Settings.from_email.orders,
          to:   to_valid_list(ssl_account.receipt_recipients)
  end

  def certificate_order_paid(contact, certificate_order, renewal=false)
    @renewal = renewal
    setup(contact, certificate_order)
    mail  subject:      "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate #{@renewal ? "Renewal Processed" : "Confirmation"} For #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from:         Settings.from_email.orders,
          to:   contact
  end

  def dcv_sent(contact, certificate_order, last_sent, host=nil)
    # host: only passed when called from delayed_job since dynamic default_url_options 
    # are not set when job runs.
    setup(contact, certificate_order)
    @host      = host
    @last_sent = last_sent
    param      = {certificate_order_id: @certificate_order.ref}
    @validation_url = if @host
      File.join(@host, new_certificate_order_validation_path(param))
    else
      new_certificate_order_validation_url(param)
    end  
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com Validation Request Will Be Sent for #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from:    Settings.from_email.orders,
          to:      contact

  end

  def dcv_email_send(certificate_order, email_address, identifier, domain_list, domain_id = nil, ssl_slug = '')
    unless certificate_order.nil?
      @certificate_order = certificate_order
      params      = {certificate_order_id: @certificate_order.ref}
      @validation_url = dcv_validate_certificate_order_validation_url(params)
      @contact = email_address
      @domains = domain_list
      @identifier = identifier
      mail subject: "Domain Control Validation for: #{certificate_order.subject} (Order ##{certificate_order.ref})",
           from:  Settings.from_email.no_reply,
           to:    @contact
    else
      params      = {ssl_slug: ssl_slug, id: domain_id}
      @validation_url = dcv_validate_domain_url(params)
      @contact = email_address
      @domains = domain_list
      @identifier = identifier
      mail subject: "Domain Control Validation for: #{domain_list[0]}",
           from:  Settings.from_email.no_reply,
           to:    @contact
    end

  end

  def processed_certificate_order(contact, certificate_order, file_path=nil, signed_certificate=nil)
    (attachments[certificate_order.friendly_common_name+'.zip'] = File.read(file_path)) unless file_path.blank?
    setup(contact, certificate_order)
    @signed_certificate=signed_certificate || certificate_order.certificate_content.csr.signed_certificate
    mail(
      to: contact,
      from: Settings.from_email.orders,
      subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate Attached For #{@signed_certificate.common_name}"
    )
  end

  def potential_trademark(contact, certificate_order, domains)
    @domains = domains
    @certificate_order=certificate_order
    mail  subject:       "Potential Trademark Issue for #{certificate_order.ref}",
          from:          Settings.from_email.no_reply,
          to:    contact
  end

  def validation_documents_uploaded(contact, certificate_order, files)
    @files=files
    setup(contact, certificate_order)
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}Validation Documents For #{certificate_order.subject} Has Been Uploaded",
          from:          Settings.from_email.no_reply,
          to:    contact
  end

  def validation_documents_uploaded_comodo(contact, certificate_order, files)
    @files=files
    setup(contact, certificate_order)
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}Validation Documents For #{certificate_order.external_order_number} Has Been Uploaded",
          from:          "support@ssl.com",
          to:    contact
  end

  def request_comodo_refund(contact, external_order_number, refund_reason, from="support@ssl.com")
    @refund_reason = refund_reason
    @external_order_number = external_order_number
    mail  subject:       "Cancel and refund #{external_order_number}",
          from:          from,
          to:    contact
  end

  def problem_ca_sending(contact, certificate_order, ca, from="support@ssl.com", error=nil)
    @ca=ca
    @error=error
    @certificate_order =  certificate_order
    mail  subject:        "Problem sending to #{@ca} for #{@certificate_order.ref}",
          from:           from,
          to:             contact
  end

  def validation_approve(contact, certificate_order)
    setup(contact, certificate_order)
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}SSL.com Certificate For #{certificate_order.subject} Has Been Approved",
          from:          Settings.from_email.orders,
          to:    contact.email
  end

  def validation_unapprove(contact, certificate_order, validation)
    setup(contact, certificate_order)
    @validation=validation
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}SSL.com Certificate For #{certificate_order.subject} Has Not Been Approved",
          from:          Settings.from_email.orders,
          to:    contact.email
  end

  def site_seal_approve(contact, certificate_order)
    setup(contact, certificate_order)
    mail  subject:    "#{'(TEST) ' if certificate_order.is_test?}SSL.com Smart SeaL For #{certificate_order.subject} Is Now Ready",
          from:       Settings.from_email.orders,
          to: (contact.is_a?(Contact) ? contact.email : contact)
  end

  def site_seal_unapprove(contact, certificate_order)
    abuse = "#{'(TEST) ' if certificate_order.is_test?}" +
        (certificate_order.site_seal.canceled? ? "Abuse Reported: " : "")
    setup(contact, certificate_order)
    mail  subject:       abuse+"SSL.com Smart SeaL For #{certificate_order.subject} Has Been Disabled",
          from:          Settings.from_email.orders,
          to:    (contact.is_a?(Contact) ? contact.email : contact)
  end

  def deposit_completed(ssl_account, deposit)
    @ssl_account= ssl_account
    @deposit    = deposit
    mail from:    Settings.from_email.orders, 
         to:      to_valid_list(ssl_account.receipt_recipients),
         subject: "SSL.com Deposit Confirmation ##{deposit.reference_number}"
  end

  def activation_confirmation(user)
    @root_url = root_url
    mail  subject:       "Activation Complete",
          from:          Settings.from_email.activations,
          to:    user.email
  end

  def signup_invitation(email, user, message)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "#{user.login} would like you to join #{Settings.community_name}!"
    @sent_on     = Time.now
    @body[:user] = user
    @body[:url]  = signup_by_id_url(user, user.invite_code)
    @body[:message] = message
  end

  def reset_password(user)
    setup_email(user)
    @subject    += "#{Settings.community_name} User information"
  end

  def forgot_username(user)
    setup_email(user)
    @subject    += "#{Settings.community_name} User information"
  end

  def api_executed(rendered, api_domain)
    @rendered = rendered
    mail  subject: "SSL.com api command executed (#{api_domain})",
          from: "noreply@ssl.com",
          to:    Settings.send_api_calls
  end

  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    setup_sender_info
    @subject     = "[#{Settings.community_name}] "
    @sent_on     = Time.now
    @body[:user] = user
  end

  def setup_sender_info
    @from       = "The #{Settings.community_name} Team <#{Settings.support_email}>"
    headers     "Reply-to" => "#{Settings.support_email}"
    @content_type = "text/plain"
  end

  def setup(contact, certificate_order)
    @contact=contact
    @certificate_order=certificate_order
  end
  
  def to_valid_list(list)
    return list.map(&:split).compact.flatten.uniq if list.is_a? Array
    return list.split.uniq if list.is_a? String
  end
end
