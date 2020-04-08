class Reminder < ApplicationMailer
  default :from => "reminder@ssl.com", :bcc => ['info@ssl.com'], return_path: "reminder@ssl.com"
  default_url_options[:host] = I18n.t('labels.ssl_ca')

  DO_NOT_SEND= %w(fiserv epsiia aturner@yisd.net cchavez@yisd.net gchavez@yisd.net ian@platinum.net d.riebeek@databaseonline.nl lsmith@patientplacement.com)

  def expiring_notice(cert, contact)
    prep(cert, contact)
    subject = "SSL.com reminder - ssl certificate for #{@cert.common_name} expires in "+ time_ago_in_words(cert.expiration_date)
    mail(:to => @to, :subject => subject)
  end

  def expired_notice(cert, contact)
    prep(cert, contact)
    subject = "SSL.com reminder - ssl certificate for #{@cert.common_name} expired "+ time_ago_in_words(cert.expiration_date) + " ago"
    mail(:to => @to, :subject => subject)
  end

  def digest_notice(d)
    preparing_recipients(d)
    @e_certs = d[1].uniq
    subject = "SSL.com reminder - ssl certificate expiration digest"
    mail(:to => @to, :subject => subject)
  end

  def digest_notify(d)
    preparing_recipients(d)
    @e_certs = d[1].uniq
    subject = "SSL.com reminder - ssl certificate expiring digest"
    mail(:to => @to, :subject => subject)
  end

  def past_expired_digest_notice(d, interval)
    @first, @last = interval.first.to_i, interval.last.to_i
    preparing_recipients(d)
    u_certs = d[1].map(&:cert).map{|c|
      [c.common_name.downcase, c]}
    cn, ed = u_certs.transpose
    if cn.uniq.count != cn.count
      diff = cn & cn.uniq
      d_hash_arry = diff.map do |dn|
        {dn => u_certs.select do |name, cert|
          cert if name == dn
        end.sort{|a,b|a[1].expiration_date <=> b[1].expiration_date}.last}
      end
      d_hash_arry.each do |d_hash|
        d_hash.each do |k,v|
          d[1].each do |ec|
            d[1].delete(ec) if ec.cert.common_name.downcase == k &&
              ec.cert.expiration_date != v[1].expiration_date
          end
        end
      end
    end
    @e_certs = d[1].uniq
    subject = "SSL.com reminder - ssl certificate expiration digest"
    mail(:to => @to, :subject => subject)
  end

  private

  def prep(cert, contact)
    @name, @cert, @contact =
      "#{contact.first_name.strip} #{contact.last_name.strip}", cert, contact
    @to="#{@name} <#{contact.email}>"
  end

  def preparing_recipients(recips)
    first_name, last_name, emails = recips[0].split(",")
    @name = "#{first_name.strip} #{last_name.strip}"
    @to=[]
    @unsubscribe='un-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32)
    emails.split(/[, ;]/).each do |e|
      if e=~EmailValidator::EMAIL_FORMAT && !DO_NOT_SEND.any?{|dns|e=~Regexp.new(dns, "i")}
        @to << e
      end
    end
  end
end
