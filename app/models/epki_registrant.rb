class EpkiRegistrant < Registrant
  serialize :domains
  alias_attribute :constraints, :domains

  def applies_to_certificate_order?(certificate_order)
    domains.any? do |domain|
      if certificate_order.certificate.is_smime_or_client?
        DomainControlValidation.domain_in_subdomains?(certificate_order.get_recipient.email.split("@")[1],domain)
      end
    end
  end
end