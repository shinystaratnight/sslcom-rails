class OrderNotifier < ApplicationMailer
  include CertificateOrdersHelper
  helper CertificateOrdersHelper

  def test
    p(caller[0] =~ /`([^']*)'/) && $1
  end
  alias something test

  def enrollment_request_for_team(team, request, team_admin)
    @url = certificate_enrollment_requests_url(
      team.to_slug, commit: true, id: request.try(:id)
    )

    mail subject: 'New Certificate Enrollment Request',
         from: orders_from_email,
         to: team_admin.email
  end

  def invoice_declined_order(params)
    @order = params[:order]
    @decline_code = params[:decline_code]
    @user_email = params[:user_email]
    mail  subject: 'Order was invoiced due to decline error from Stripe merchant.',
          from: orders_from_email,
          to: support_email
  end

  def order_transferred(params)
    @order_list = params[:orders_list]
    @co_list    = params[:co_list]
    @user       = params[:user].email
    @from_team  = params[:from_sa]
    @to_team    = params[:to_sa]
    @from_owner = @from_team.get_account_owner.email
    @to_owner   = @to_team.get_account_owner.email

    mail  subject: "Order(s) have been transferred from team #{@from_team.get_team_name} to team #{@to_team.get_team_name}.",
          from: orders_from_email,
          to: [@from_owner, @to_owner].uniq
  end

  def domains_adjustment_new(params)
    @user  = params[:user]
    @order = params[:order]
    @team  = @order.billable

    mail  subject: "A new domains adjustment order has been placed for team #{@team.get_team_name}.",
          from: orders_from_email,
          to: @user.email
  end

  def payable_invoice_new(params)
    @user    = params[:user]
    @invoice = params[:invoice]
    @team    = @invoice.billable
    @invoice_type = @invoice.get_type_format.downcase

    mail  subject: "You have a new invoice for team #{@team.get_team_name}.",
          from: orders_from_email,
          to: @user.email
  end

  def payable_invoice_paid(params)
    @user    = params[:user]
    @paid_by = params[:paid_by]
    @invoice = params[:invoice]
    @team    = @invoice.billable
    @invoice_type = @invoice.get_type_format.downcase

    mail  subject: "Payment has been submitted for invoice ##{@invoice.reference_number} for team #{@team.get_team_name}.",
          from: orders_from_email,
          to: @user.email
  end

  def reseller_certificate_order_paid(ssl_account, certificate_order)
    @ssl_account        = ssl_account
    @certificate_order  = certificate_order.reload
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description['certificate_type']} Certificate Confirmation For #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from: orders_from_email,
          to: certificate_order.valid_recipients_list
  end

  def certificate_order_prepaid(ssl_account, order)
    @ssl_account  = ssl_account
    @order        = order
    mail  subject: "SSL.com Confirmation for Order ##{order.reference_number}",
          from: orders_from_email,
          to: to_valid_list(ssl_account.receipt_recipients)
  end

  def certificate_order_paid(contact, certificate_order, renewal = false)
    @renewal = renewal
    setup(contact, certificate_order)
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description['certificate_type']} Certificate #{@renewal ? 'Renewal Processed' : 'Confirmation'} For #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from: orders_from_email,
          to: contact
  end

  def dcv_sent(contact, certificate_order, last_sent, host = nil)
    # host: only passed when called from delayed_job since dynamic default_url_options
    # are not set when job runs.
    setup(contact, certificate_order)
    @host      = host
    @last_sent = last_sent
    param      = { certificate_order_id: @certificate_order.ref }
    @validation_url = if @host
                        File.join(@host, new_certificate_order_validation_path(param))
                      else
                        new_certificate_order_validation_url(param)
                      end
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com Validation Request Will Be Sent for #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from: orders_from_email,
          to: contact
  end

  # TODO: refactor to scan all teams that belong to an emailed recipient and remove the ssl_slug - it's causing too many problems
  def dcv_email_send(email_address, identifier, domain_list, domain_id = nil, ssl_slug = '', dcv_type = 'cert')
    @contact = email_address
    @domains = domain_list
    @identifier = identifier
    subject = 'Domain Control Validation for: '
    subject << domain_list.join(', ').to_s
    if dcv_type == 'team'
      params = { ssl_slug: ssl_slug, id: domain_id }
      @validation_url = dcv_validate_domain_url(params)
    else
      params = { ssl_slug: ssl_slug }
      @validation_url = dcv_all_validate_domains_url(params)
    end
    mail subject: subject,
         from: no_reply_email,
         to: @contact
  end

  def processed_certificate_order(options)
    (attachments[options[:certificate_order].friendly_common_name + '.zip'] = File.read(options[:file_path])) if options[:file_path].present?
    setup(options[:contact], options[:certificate_order])
    @certificate_content = options[:certificate_content] || options[:certificate_order].certificate_content
    @signed_certificate = options[:signed_certificate] || @certificate_content ?
        @certificate_content.signed_certificate : options[:certificate_order].signed_certificate
    mail(
      to: options[:contact],
      from: orders_from_email,
      subject: "#{'(TEST) ' if options[:certificate_order].is_test?}SSL.com #{options[:certificate_order].certificate.description['certificate_type']} Certificate (#{@signed_certificate.validation_type.upcase}) Attached For #{@signed_certificate.common_name}"
    )
  end

  def potential_trademark(contact, certificate_order, domains)
    cc = certificate_order.certificate_content
    if cc.preferred_process_pending_server_certificates
      cc.preferred_process_pending_server_certificates = false
      cc.preferred_process_pending_server_certificates_will_change!
    end

    @domains = domains
    @certificate_order = certificate_order
    mail  subject: "Potential Trademark Issue for #{certificate_order.ref}",
          from: no_reply_email,
          to: contact
  end

  def validation_documents_uploaded(contact, certificate_order, files)
    @files = files
    setup(contact, certificate_order)
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}Validation Documents For #{certificate_order.subject} Has Been Uploaded",
          from: no_reply_email,
          to: contact
  end

  def validation_documents_uploaded_comodo(contact, certificate_order, files)
    @files = files
    setup(contact, certificate_order)
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}Validation Documents For #{certificate_order.external_order_number} Has Been Uploaded",
          from: 'support@ssl.com',
          to: contact
  end

  def request_comodo_refund(contact, external_order_number, refund_reason, from = 'support@ssl.com')
    @refund_reason = refund_reason
    @external_order_number = external_order_number
    mail  subject: "Cancel and refund #{external_order_number}",
          from: from,
          to: contact
  end

  def problem_ca_sending(contact, certificate_order, ca, from = 'support@ssl.com', error = nil)
    @ca = ca
    @error = error
    @certificate_order = certificate_order
    mail  subject: "Problem sending to #{@ca} for #{@certificate_order.ref}",
          from: from,
          to: contact
  end

  def validation_approve(contact, certificate_order)
    setup(contact, certificate_order)
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com Certificate For #{certificate_order.subject} Has Been Approved",
          from: orders_from_email,
          to: contact.email
  end

  def validation_unapprove(contact, certificate_order, validation)
    setup(contact, certificate_order)
    @validation = validation
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com Certificate For #{certificate_order.subject} Has Not Been Approved",
          from: orders_from_email,
          to: contact.email
  end

  def site_seal_approve(contact, certificate_order)
    setup(contact, certificate_order)
    mail  subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com Smart SeaL For #{certificate_order.subject} Is Now Ready",
          from: orders_from_email,
          to: (contact.is_a?(Contact) ? contact.email : contact)
  end

  def site_seal_unapprove(contact, certificate_order)
    abuse = ('(TEST) ' if certificate_order.is_test?).to_s +
            (certificate_order.site_seal.canceled? ? 'Abuse Reported: ' : '')
    setup(contact, certificate_order)
    mail  subject: abuse + "SSL.com Smart SeaL For #{certificate_order.subject} Has Been Disabled",
          from: orders_from_email,
          to: (contact.is_a?(Contact) ? contact.email : contact)
  end

  def deposit_completed(ssl_account, deposit)
    @ssl_account = ssl_account
    @deposit = deposit
    mail from: orders_from_email,
         to: to_valid_list(ssl_account.receipt_recipients),
         subject: "SSL.com Deposit Confirmation ##{deposit.reference_number}"
  end

  def activation_confirmation(user)
    @root_url = root_url
    mail  subject: 'Activation Complete',
          from: activations_from_email,
          to: user.email
  end

  def signup_invitation(email, user, message)
    setup_sender_info
    @recipients  = email.to_s
    @subject     = "#{user.login} would like you to join #{community_name}!"
    @sent_on     = Time.zone.now
    @body[:user] = user
    @body[:url]  = signup_by_id_url(user, user.invite_code)
    @body[:message] = message
  end

  def reset_password(user)
    setup_email(user)
    @subject += "#{community_name} User information"
  end

  def forgot_username(user)
    setup_email(user)
    @subject += "#{community_name} User information"
  end

  def api_executed(rendered, api_domain)
    @rendered = rendered
    mail  subject: "SSL.com api command executed (#{api_domain})",
          from: 'noreply@ssl.com',
          to: Settings.send_api_calls
  end

  def certificate_order_token_send(co, token)
    @activation_link = confirm_url(token)
    @certificate_order = co
    @company_name = @certificate_order.locked_registrant ? @certificate_order.locked_registrant.company_name : ''

    mail subject: 'Certificate Activation Link',
         from: no_reply_email,
         to: co.get_download_cert_email
  end

  def serial_number_entropy(revocation_notification)
    @revocation_notification = revocation_notification
    mail subject: 'SSL.com Certificate Replacement Due to Serial Number Entropy',
         from: no_reply_email,
         to: revocation_notification.email
  end

  def request_token_send(co, user, requestor)
    @certificate_order = co
    @user = user
    @requestor = requestor

    mail subject: 'Certificate Activation Link',
         from: no_reply_email,
         to: user.email
  end

  def callback_send(co, token, email)
    phone_number = co.locked_registrant.blank? ? '' : co.locked_registrant.phone || ''
    country_code = co.locked_registrant.blank? ? '' : co.locked_registrant.country_code || '1'
    @telephone = '+' + country_code + '-' + phone_number
    @validation_link = email_verification_url(token)

    mail subject: "SSL.com callback verification for certificate ref #{co.ref}",
         from: no_reply_email,
         to: email
  end

  def manual_callback_send(co, datetime)
    @date_time = datetime
    mail subject: "Manual Callback for certificate ref : \"#{co.ref}\"",
         from: no_reply_email,
         to: support_email
  end

  def problem(system_audit)
    @system_audit = system_audit
    mail subject: 'A problem has been detected',
         from: no_reply_email,
         to: support_email
  end

  def request_phone_number_approve(co, to_email)
    @co_edit_page_path = edit_certificate_order_url(id: co.ref, registrant: false, approve_phone: true)
    @cert_order_ref = co.ref

    mail subject: 'Request for approving Phone Number',
         from: no_reply_email,
         to: to_email
  end

  def notify_phone_number_approve(co, _from_email)
    phone_number = co.locked_registrant.phone
    country_code = co.locked_registrant.country_code
    @phone_number = '(+' + country_code + ') ' + phone_number
    @cert_order_ref = co.ref

    mail subject: 'Approved Phone Number',
         from: no_reply_email,
         to: co.get_download_cert_email
  end

  protected

  def setup_email(user)
    @recipients = user.email.to_s
    setup_sender_info
    @subject = "[#{community_name}] "
    @sent_on = Time.zone.now
    @body ||= {}
    @body[:user] = user
  end

  def setup_sender_info
    @from = "The #{community_name} Team <#{support_email}>"
    headers 'Reply-to' => support_email.to_s
    @content_type = 'text/plain'
  end

  def setup(contact, certificate_order)
    @contact = contact
    @certificate_order = certificate_order
  end

  def to_valid_list(list)
    if list.is_a? Array
      list.delete(true)
      return list.map(&:split).compact.flatten.uniq
    end
    return list.split.uniq if list.is_a? String
  end
end
