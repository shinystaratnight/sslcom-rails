# https://anotherengineeringblog.com/extract-parse-digital-certificates-with-ruby

require 'delegate'
require 'date'

class DigitalCertificate < SimpleDelegator
  def subject
    __getobj__.subject.to_s
  end

  def issuer
    __getobj__.issuer.to_s
  end

  def serial
    __getobj__.serial.to_s(16).scan(/.{1,2}/).join(' ')
  end

  def extensions
    __getobj__.extensions.map(&:value)
  end

  def valid_from
    __getobj__.not_before.to_s
  end

  def valid_to
    __getobj__.not_after.to_s
  end

  def thumbprint
    OpenSSL::Digest::SHA1.new(__getobj__.to_der).to_s.upcase
  end

  def root_certificate?(subjects)
    !subjects.include?(issuer) && !time_stamping_certificate?
  end

  def time_stamping_certificate?
    extension_match = extensions.any? { |ext| ext =~ /time\s*stamp/i }
    extension_match || subject =~ /time\s*stamp/i
  end

  def to_db
    { issuer: issuer, subject: subject, serial_no: serial,
      thumbprint: thumbprint, algorithm: signature_algorithm,
      valid_from: DateTime.parse(valid_from),
      valid_to: DateTime.parse(valid_to)
    }
  end
end
