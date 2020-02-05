# frozen_string_literal: true

class WhoIsJob < Struct.new(:dname, :certificate_name)
  def perform
    dcv = global_validations.find_by_subject(dname)
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
      global_validations.find_or_create_by(subject: dname).update_column(:candidate_addresses, standard_addresses)
    end
    Rails.cache.write("CertificateName.candidate_email_addresses/#{dname}", standard_addresses, expires_in: DomainControlValidation::EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days)
    touch_cnames(dname)
    certificate_name&.domain_control_validations&.last&.update_column(:candidate_addresses, standard_addresses)
  end

  def max_attempts
    3
  end

  def touch_cnames(dname)
    current_time = Time.zone.now
    cert_names = CertificateName.where('name = ?', dname.to_s)
    cert_names.update_all(updated_at: current_time)
    cert_names.each{ |cn| Rails.cache.delete(cn.get_asynch_cache_label) }
    CertificateContent.where{ id >> cert_names.map(&:certificate_content_id) }.update_all(updated_at: current_time)
  end

  def max_run_time
    300 # seconds
  end

  def global_validations
    @global_validations ||= DomainControlValidation.global
  end
end
