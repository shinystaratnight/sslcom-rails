# https://anotherengineeringblog.com/extract-parse-digital-certificates-with-ruby

class DigitalCertificateParser
  attr_reader :all_certificates

  def initialize(digital_signature)
    if !digital_signature.instance_of?(OpenSSL::PKCS7)
      raise InvalidSignatureError, 'Signature is not a PKCS7'
    end
    @all_certificates = digital_signature.certificates.map do |cert|
      DigitalCertificate.new(cert)
    end
  end

  def chains
    @chains ||= build_chains
  end

  def end_user_certificate
    first_chain = chains[0]
    first_chain.last if first_chain
  end

  def root_certificate
    first_chain = chains[0]
    first_chain.first if first_chain
  end

  private

  def build_chains
    chains = []
    root_certs = find_root_certs
    root_certs.each_with_index do |cert, index|
      chains[index] = [cert]
      while (next_certificate = find_next_in_chain(chains[index].last))
        chains[index] << next_certificate
      end
    end
    chains
  end

  def find_next_in_chain(parent_cert)
    all_certificates.find do |cert|
      cert.issuer == parent_cert.subject && !cert.time_stamping_certificate?
    end
  end

  def find_root_certs
    subjects = all_certificates.map(&:subject)
    all_certificates.select do |certificate|
      certificate.root_certificate?(subjects.delete(certificate.subject))
    end
  end
end

