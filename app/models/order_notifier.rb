class OrderNotifier < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  helper CertificateOrdersHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods
  default_url_options[:host] = Settings.actionmailer_host

  def reseller_certificate_order_paid(ssl_account, certificate_order)
    subject       "SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate Confirmation For #{certificate_order.subject} (Order ##{certificate_order.ref})"
    from          Settings.from_email.orders
    recipients    certificate_order.receipt_recipients
    sent_on       Time.now
    body          :ssl_account=>ssl_account, :certificate_order=>certificate_order.reload
  end

  def certificate_order_prepaid(ssl_account, order)
    subject       "SSL.com Confirmation for Order ##{order.reference_number}"
    from          Settings.from_email.orders
    recipients    ssl_account.receipt_recipients
    sent_on       Time.now
    body          :ssl_account=>ssl_account, :order=>order
  end

  def certificate_order_paid(contact, certificate_order)
    subject       "SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate Confirmation For #{certificate_order.subject} (Order ##{certificate_order.ref})"
    from          Settings.from_email.orders
    recipients    contact
    sent_on       Time.now
    body          :contact=>contact, :certificate_order=>certificate_order
  end

  def dcv_sent(contact, certificate_order, last_sent)
    subject       "SSL.com Validation Request Will Be Sent for #{certificate_order.subject} (Order ##{certificate_order.ref})"
    from          Settings.from_email.orders
    recipients    contact
    sent_on       Time.now
    body          :contact=>contact, :certificate_order=>certificate_order, last_sent: last_sent
  end

  def processed_certificate_order(contact, certificate_order, file_path)
    attachments[certificate_order.friendly_common_name+'.zip'] = File.read(file_path)
    @contact=contact
    @certificate_order=certificate_order
    @signed_certificate=certificate_order.certificate_content.csr.signed_certificate
    mail(
      to: contact,
      from: Settings.from_email.orders,
      subject: "SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate Attached For #{certificate_order.subject}"
    )
  end

  def validation_approve(contact, certificate_order)
    subject       "SSL.com Certificate For #{certificate_order.subject} Has Been Approved"
    from          Settings.from_email.orders
    recipients    contact.email
    sent_on       Time.now
    body          :contact=>contact, :certificate_order=>certificate_order
  end

  def validation_unapprove(contact, certificate_order, validation)
    subject       "SSL.com Certificate For #{certificate_order.subject} Has Not Been Approved"
    from          Settings.from_email.orders
    recipients    contact.email
    sent_on       Time.now
    body          :contact=>contact, :certificate_order=>certificate_order,
                  :validation=>validation
  end

  def site_seal_approve(contact, certificate_order)
    subject       "SSL.com Smart SeaL For #{certificate_order.subject} Is Now Ready"
    from          Settings.from_email.orders
    recipients    contact.is_a?(Contact) ? contact.email : contact
    sent_on       Time.now
    body          :contact=>contact, :certificate_order=>certificate_order
  end

  def site_seal_unapprove(contact, certificate_order)
    abuse = certificate_order.site_seal.canceled? ? "Abuse Reported: " : ""
    subject       abuse+"SSL.com Smart SeaL For #{certificate_order.subject} Has Been Disabled"
    from          Settings.from_email.orders
    recipients    contact.is_a?(Contact) ? contact.email : contact
    sent_on       Time.now
    body          :contact=>contact, :certificate_order=>certificate_order
  end

  def deposit_completed(ssl_account, deposit)
    subject       "SSL.com Deposit Confirmation ##{deposit.reference_number}"
    from          Settings.from_email.orders
    recipients    ssl_account.receipt_recipients
    sent_on       Time.now
    body          :ssl_account=>ssl_account, :deposit=>deposit
  end

  def activation_confirmation(user)
    subject       "Activation Complete"
    from          Settings.from_email.activations
    recipients    user.email
    sent_on       Time.now
    body          :root_url => root_url
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
  
end
