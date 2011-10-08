module CertificateOrdersHelper
  def order_line_items(certificate_order, email_template=false)
    items = []
    if certificate_order.certificate.is_ucc? ||
        certificate_order.certificate.is_wildcard?
      soi = certificate_order.sub_order_items.detect{|item|item.
          product_variant_item.is_server_license?}
      unless soi.blank?
        items << pluralize(soi.quantity+1, "server license")
        if certificate_order.certificate.is_ucc?
          soid = certificate_order.sub_order_items.find_all{|item|item.
              product_variant_item.is_domain?}
          quantity = soid.sum(&:quantity)
          unless certificate_order.certificate_contents.empty?
            if email_template
              domains = certificate_order.
                certificate_content.domains.join(", ")
              items << "domains - " +   (domains.empty? ? "" : "("+domains+")")
            else
              domains = certificate_order.
                certificate_content.domains.join(", ")
              items << content_tag(:dt,pluralize(quantity, "domain")) +
                (domains.empty? ? "" : content_tag(:dd,"("+domains+")"))
            end
          end
        end
      end
    end
    unless certificate_order.migrated_from_v2?
      items << "SSL Secured Seal"
      items << "SSL daily site monitoring"
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
          'please wait'
        when "issued"
          if certificate_content.expired?
            if certificate_order.renewal && certificate_order.renewal.paid?
              link_to 'see renewal', certificate_order_path(certificate_order)
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
    !(certificate_order.ssl_account==current_user.ssl_account)
  end

  def certificate_order_status(certificate_content=nil)
    return if certificate_content.blank?
    if certificate_content.new?
      'waiting for csr'
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

  def test
s=<<-EOS
MIIPSQYJKoZIhvcNAQcCoIIPOjCCDzYCAQExADALBgkqhkiG9w0BBwGggg8eMIIF
4DCCBMigAwIBAgIQZLLNZYA0OORv9VJR5Vva+jANBgkqhkiG9w0BAQUFADCBiTEL
MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
BxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxLzAtBgNVBAMT
JkNPTU9ETyBIaWdoLUFzc3VyYW5jZSBTZWN1cmUgU2VydmVyIENBMB4XDTExMTAw
NzAwMDAwMFoXDTEyMTAwNjIzNTk1OVowggEAMQswCQYDVQQGEwJVUzEOMAwGA1UE
ERMFOTM0NjMxEzARBgNVBAgTCkNhbGlmb3JuaWExEDAOBgNVBAcTB1NvbHZhbmcx
GjAYBgNVBAkTETIwMjkgVmlsbGFnZSBMYW5lMRkwFwYDVQQKExB3d3cubXl0bm1h
aWwuY29tMR4wHAYDVQQLExVEaXNjb3VudCBEb21haW5zIFBsdXMxMzAxBgNVBAsT
Kkhvc3RlZCBieSBTZWN1cmUgU29ja2V0cyBMYWJvcmF0b3JpZXMsIExMQzETMBEG
A1UECxMKSW5zdGFudFNTTDEZMBcGA1UEAxMQd3d3Lm15dG5tYWlsLmNvbTCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN++DJvzCjEXrfCSTNNibqcpaqta
Mud9yKN/O3Ooxhygz0fMPSYN1TQHBYgF2D/71NzmWZf3GhXqTPep2NeN6/2x38iC
v+DldHiskT1WXPiyO6YQ6AgdlJTBBOycbS3RcMcEY9ZOBBhFmWAK/jP5GHY4Wn2S
sXB3uBmNFfkAJxgCx8IZWJNPrh18548URkcrGHw0rgmNwKXwqesLt7S1B4xqAuhD
7WwQnT5z8dQKXv2+GEtpma3nri+++nP4ONRKVbenTS0EL4e9rJWwNAfv+T/lEdVk
5Ma/+tMxcmiYAW2BJMKE+sMMszc+427EW/t9ZUL+ydXo8U1hn4nOh4pGZ30CAwEA
AaOCAcgwggHEMB8GA1UdIwQYMBaAFD/VtdDWRHlQShejm4xK3LiwImRrMB0GA1Ud
DgQWBBQ/lpo/ehOmCqEntv0ll6X8RI3ucjAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0T
AQH/BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwRgYDVR0gBD8w
PTA7BgwrBgEEAbIxAQIBAwQwKzApBggrBgEFBQcCARYdaHR0cHM6Ly9zZWN1cmUu
Y29tb2RvLmNvbS9DUFMwTwYDVR0fBEgwRjBEoEKgQIY+aHR0cDovL2NybC5jb21v
ZG9jYS5jb20vQ09NT0RPSGlnaC1Bc3N1cmFuY2VTZWN1cmVTZXJ2ZXJDQS5jcmww
gYAGCCsGAQUFBwEBBHQwcjBKBggrBgEFBQcwAoY+aHR0cDovL2NydC5jb21vZG9j
YS5jb20vQ09NT0RPSGlnaC1Bc3N1cmFuY2VTZWN1cmVTZXJ2ZXJDQS5jcnQwJAYI
KwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNvbW9kb2NhLmNvbTApBgNVHREEIjAgghB3
d3cubXl0bm1haWwuY29tggxteXRubWFpbC5jb20wDQYJKoZIhvcNAQEFBQADggEB
AKgKafRgvLG8Sa87v0WuUMHlLRsy8nNkQeOk/j+lwITEu6l0+qbjgmrU4rVoqBDD
w9awDdwwqHOeryytOTF5ExNih/S0lpW7BpwfwJ4JpivztlgkFQFxv2OrkwYwp9ec
yt3djwDtwFbBY5WcK6doreyIu/uQlkS8x1iJvZxVV0oqNPkRT5PE+SXz0nGW8l3R
xJfbqv23GdP3AKipIgur5OLnCVfz8x/WQkTixL0JRB76EnTBieFWvLl0g5sWHIpq
Mc6mTKxP3dhOZ/EdQwe1O2d9VXvAmfkTW191OCSm/ZezAg866R9pevVuaoLfJ6vM
UI6qwcRnnXJ1rwgUoXTG8SswggT8MIID5KADAgECAhAWkMMptngGB1EfBbA0SEbL
MA0GCSqGSIb3DQEBBQUAMG8xCzAJBgNVBAYTAlNFMRQwEgYDVQQKEwtBZGRUcnVz
dCBBQjEmMCQGA1UECxMdQWRkVHJ1c3QgRXh0ZXJuYWwgVFRQIE5ldHdvcmsxIjAg
BgNVBAMTGUFkZFRydXN0IEV4dGVybmFsIENBIFJvb3QwHhcNMTAwNDE2MDAwMDAw
WhcNMjAwNTMwMTA0ODM4WjCBiTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0
ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RP
IENBIExpbWl0ZWQxLzAtBgNVBAMTJkNPTU9ETyBIaWdoLUFzc3VyYW5jZSBTZWN1
cmUgU2VydmVyIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA54fa
wHfkuzr6aiTIgEGs0hYTFT369/gqdtyoLTkIzkhKvg998N66u0fVvS3XG6sPIIEj
CHKxwBGVDebqqYf/x24eT2YyulO8BaocLAzvTTdHaxAM28WgmH5Y2zfWrukGvdeo
ZfM3ucdtznfHJuDXdB+mmBa7DGvIvnfQ71inKaC5uGkFNsuy2lijC3WtPYsigiA+
cIaZHLlPz3ekBxojY9E4VoTsv4/FTvQYlpsa6JPsja8VnCTwWjvoD7moWgHTshxg
yZxSBN2Sp/4MrOJFjQNhvHngdy6HQTxYX8v1xXfyWMhNKNCa+vNzCSRodLwgTNgs
sKro2U5t8owk05NdkQIDAQABo4IBdzCCAXMwHwYDVR0jBBgwFoAUrb2YejS0Jvf6
xCZU7wO94CTLVBowHQYDVR0OBBYEFD/VtdDWRHlQShejm4xK3LiwImRrMA4GA1Ud
DwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMBEGA1UdIAQKMAgwBgYEVR0g
ADBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vQWRk
VHJ1c3RFeHRlcm5hbENBUm9vdC5jcmwwgbMGCCsGAQUFBwEBBIGmMIGjMD8GCCsG
AQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5jb20vQWRkVHJ1c3RFeHRlcm5h
bENBUm9vdC5wN2MwOQYIKwYBBQUHMAKGLWh0dHA6Ly9jcnQudXNlcnRydXN0LmNv
bS9BZGRUcnVzdFVUTlNHQ0NBLmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29jc3Au
dXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQUFAAOCAQEAE4UfUoAYyVP3/i4ar8zZ
CzzC04WBEPAojblAfiyej9Y2hgpMFC3Wl0OSQRk3S5ae66kweRKVswI2V+0ruR2Y
GqMYCj+bOYvNoUkpTC/50JWMyE2VuqhDzzOqJSpaDqonyU5rseZzH7N0BMPzTOKo
62e3XbgIBRpWmlQphfUpToA7ldB7U5YRVsEC0+qyf8qPnHBKFI1auRZgddbNJx4W
zVszjnlAzyhI59xxFk50kXW5KozxcKwm3QS5QMKF3hyTQNDMbsObqu9gZd9gIvBa
pXqiL+Rwc+481CYraAfBIHromFo+e58Ci2LAhYGAYDV+pR0M0pzfYkUN2/w3+/Ul
IjCCBDYwggMeoAMCAQICAQEwDQYJKoZIhvcNAQEFBQAwbzELMAkGA1UEBhMCU0Ux
FDASBgNVBAoTC0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5h
bCBUVFAgTmV0d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9v
dDAeFw0wMDA1MzAxMDQ4MzhaFw0yMDA1MzAxMDQ4MzhaMG8xCzAJBgNVBAYTAlNF
MRQwEgYDVQQKEwtBZGRUcnVzdCBBQjEmMCQGA1UECxMdQWRkVHJ1c3QgRXh0ZXJu
YWwgVFRQIE5ldHdvcmsxIjAgBgNVBAMTGUFkZFRydXN0IEV4dGVybmFsIENBIFJv
b3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC39xoz5vIABC054E5b
7R+8bA/Ntfojts7emxEzl6QpTH2Tn71KvJPtAxrjj8/lbVBa1pcplFqAsEl62y6V
/bjKvzc4LR4+kUGtcFbH8E8/6DKedMrIkFTpxl8PeJ2aQDwOrGGqXhSPnoehalDc
15pOrwWzpnGUnHGzUGAKxxOdOAeGAqjpqGkmGJCrTLBPI6s6T4TY386f4Wlvu9dC
12tE5Met7m1BX3JacQg3s3llpFmglDf3AC8NwpJy2tA4ctsUqEXEXSp9t7TWxO6s
zRNEt8kr3UMAJfphuWlqWCMRt6czj1Z1WfXNKddGtworZbbTQm8Vsrh7++/pXVPV
NFonAgMBAAGjgdwwgdkwHQYDVR0OBBYEFK29mHo0tCb3+sQmVO8DveAky1QaMAsG
A1UdDwQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MIGZBgNVHSMEgZEwgY6AFK29mHo0
tCb3+sQmVO8DveAky1QaoXOkcTBvMQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRk
VHJ1c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3Jr
MSIwIAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBDQSBSb290ggEBMA0GCSqGSIb3
DQEBBQUAA4IBAQCwm+CFJcLWI+IPlgaSnUGYnNmEeYHZHlsUByM2ZY+w2He7rEFs
R2CDUbD5Mj3n/PYmE8eAFqW/WvyHz3h5iSGa4kwHCoY1vPLeUcTSlrfcfk7ucP0c
OesMAlEULY69FuDB30Z15ySt7PRCtIWTcBBnup0GNUoY0yt6zFFCoXpj0ea7ocUr
wja+Ew3mvWN+eXunCQ1Aq2rdj4rD9vaMGkIFUdRF9Z+nYiFoFSBDPJnnfL0k2KmR
F3OIP1YbMTgYtHEPms3IDp6OLhvhjJiDyx8x8URMxgRzSXZgD8f4vReAay7pzEwO
Wpp5DyAKLtWeYyYeVZKU2IIXWnvQvMePToYEMQA=
EOS
    sc=OpenSSL::PKCS7.new s
    sc
  end
end
