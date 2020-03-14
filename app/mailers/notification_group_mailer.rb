class NotificationGroupMailer < ApplicationMailer
  default from: "reminder@ssl.com", bcc: 'info@ssl.com', return_path: "reminder@ssl.com"
  track user: -> { User.find_by(email: message.to) }

  def expiration_notice(notification_group, scanned_certificates, contacts, ssl_account)
    @notification_group = notification_group
    @scanned_certificates = scanned_certificates
    @ssl_account = ssl_account
    subject = "SSL.com reminder - domain expiration reminder for notification group #{@notification_group.friendly_name || @notification_group.ref}"
    mail(to: contacts, subject: subject)
  end

  def domain_digest_notice(scan_status, notification_group, scanned_certificate, domain, contacts, ssl_account)
    if scan_status == 'ok'
      up_or_down = 'UP'
    else
      up_or_down = 'DOWN'
    end

    @scan_status = scan_status
    @scanned_certificate = scanned_certificate
    @notification_group = notification_group
    @ssl_account = ssl_account
    @domain = domain
    subject = "SSL.com #{@notification_group.friendly_name || @notification_group.friendly_name.ref} Alert: #{@domain} is #{up_or_down} [SSL/TLS: #{@scan_status}]"
    mail(to: contacts, subject: subject)
  end
end
