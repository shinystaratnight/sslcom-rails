# frozen_string_literal: true

class WhoIsJob < Struct.new(:dname, :certificate_name)
  def perform
    dcv = DomainControlValidation.global.find_by_subject(dname)
    if dcv
      standard_addresses = dcv.candidate_addresses
    else
      standard_addresses = DomainControlValidation.email_address_choices(dname)
      begin
        d = ::PublicSuffix.parse(dname)
        whois = Whois.whois(ActionDispatch::Http::URL.extract_domain(d.domain, 1)).to_s
        whois_addresses = WhoisLookup.email_addresses(whois.gsub(/^.*?abuse.*?$/i, '')) # remove any line with 'abuse'
        unless whois_addresses.blank?
          whois_addresses.each do |ad|
            standard_addresses << ad.downcase
          end
        end
      rescue StandardError => e
        Logger.new(STDOUT).error e.backtrace.inspect
      end
      DomainControlValidation.global.find_or_create_by(subject: dname).update_column(:candidate_addresses, standard_addresses)
    end
    Rails.cache.write("CertificateName.candidate_email_addresses/#{dname}", standard_addresses, expires_in: DomainControlValidation::EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days)
    cert_names = CertificateName.where('name = ?', dname.to_s)
    cert_names.update_all(updated_at: Time.now)
    cert_names.each{ |cn| Rails.cache.delete(cn.get_asynch_cache_label) }
    CertificateContent.where{ id >> cert_names.map(&:certificate_content_id) }.update_all(updated_at: Time.now)
    if certificate_name
      dcv = certificate_name.domain_control_validations.last
      dcv&.update_column(:candidate_addresses, standard_addresses)
    end
  end

  def max_attempts
    3
  end

  def max_run_time
    300 # seconds
  end
end
