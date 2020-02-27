class NotificationGroupMailer < ApplicationMailer
  default from: "reminder@ssl.com", bcc: 'info@ssl.com', return_path: "reminder@ssl.com"

  def expiration_notice(notification_group, scanned_certificates, contacts, ssl_account)
    @notification_group = notification_group
    @scanned_certificates = scanned_certificates
    @ssl_account = ssl_account
    subject = "SSL.com reminder - domain expiration reminder for notification group #{@notification_group.friendly_name || @notification_group.ref}"
    mail(to: contacts.pluck(:email_address).uniq, subject: subject)
  end
end
