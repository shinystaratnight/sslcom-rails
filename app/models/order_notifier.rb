class OrderNotifier < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  helper CertificateOrdersHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods
  default_url_options[:host] = Settings.actionmailer_host

  def test
    p caller[0] =~ /`([^']*)'/ and $1
  end
  alias_method :something, :test

  def reseller_certificate_order_paid(ssl_account, certificate_order)
    @ssl_account        = ssl_account
    @certificate_order  = certificate_order.reload
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate Confirmation For #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from:          Settings.from_email.orders,
          to:    certificate_order.receipt_recipients

  end

  def certificate_order_prepaid(ssl_account, order)
    @ssl_account  = ssl_account
    @order        = order
    mail  subject: "SSL.com Confirmation for Order ##{order.reference_number}",
          from: Settings.from_email.orders,
          to:    ssl_account.receipt_recipients.uniq
  end

  def certificate_order_paid(contact, certificate_order, renewal=false)
    @renewal = renewal
    setup(contact, certificate_order)
    mail  subject:      "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate #{@renewal ? "Renewal Processed" : "Confirmation"} For #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from:         Settings.from_email.orders,
          to:   contact
  end

  def dcv_sent(contact, certificate_order, last_sent)
    setup(contact, certificate_order)
    @last_sent=last_sent
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}SSL.com Validation Request Will Be Sent for #{certificate_order.subject} (Order ##{certificate_order.ref})",
          from:          Settings.from_email.orders,
          to:    contact

  end

  def processed_certificate_order(contact, certificate_order, file_path)
    attachments[certificate_order.friendly_common_name+'.zip'] = File.read(file_path)
    setup(contact, certificate_order)
    @signed_certificate=certificate_order.certificate_content.csr.signed_certificate
    mail(
      to: contact,
      from: Settings.from_email.orders,
      subject: "#{'(TEST) ' if certificate_order.is_test?}SSL.com #{certificate_order.certificate.description["certificate_type"]} Certificate Attached For #{certificate_order.subject}"
    )
  end

  def validation_documents_uploaded(contact, certificate_order, files)
    @files=files
    setup(contact, certificate_order)
    mail  subject:       "#{'(TEST) ' if certificate_order.is_test?}Validation Documents For #{certificate_order.subject} Has Been Uploaded",
          from:          Settings.from_email.orders,
          to:    contact
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
    mail from: Settings.from_email.orders, to: ssl_account.receipt_recipients, subject: "SSL.com Deposit Confirmation ##{deposit.reference_number}"
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

  def api_executed(rendered)
    @rendered = rendered
    mail  subject: "SSL.com api command executed",
          from: "noreply@ssl.com",
          to:    "api@ssl.com"
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

end
