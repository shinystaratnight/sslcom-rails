module CertificateType
  def is_dv?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_DV))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(basic|free)/
    end
  end

  def is_ov?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_OV))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :
           self).product =~ /\A(wildcard|high_assurance|ucc|premiumssl)/ ||
          is_client_enterprise? || is_client_business? || is_client_pro?
    end
  end
  
  def is_ev?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_EV))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\Aev(?!\-code)/
    end
  end

  def is_iv?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_IV))
    else
      # (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(basic|free)/
    end
  end

  def is_evcs?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_EVCS))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\Aev-code-signing/
    end
  end

  # implies non EV
  def is_cs?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_CS))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(code[_\-]signing)/
    end
  end

  # this covers both ev and non ev code signing
  def is_code_signing?
    is_cs? or is_evcs? or is_client? # is_client is temporary
  end

  def is_test_certificate?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_TEST))
    else
      # (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(basic|free)/
    end
  end

  def is_smime?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\Asmime/
  end

  def is_client?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product.include?('personal')
  end

  def is_client_basic?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/basic\z/
  end

  def is_client_pro?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/pro\z/
  end

  def is_client_business?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/business\z/
  end

  def is_client_enterprise?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/enterprise\z/
  end

  def is_ov_client?
    is_client_enterprise? or is_client_business?
  end

  def requires_company_info?
    is_client_business? || is_client_enterprise? || is_server? || is_code_signing? || is_ov?
  end

  def comodo_ca_id
    if is_ev?
      Settings.ca_certificate_id_ev
    elsif is_ov?
      Settings.ca_certificate_id_ov
    else
      Settings.ca_certificate_id_dv
    end
  end

  def validation_type
    if is_dv?
      "dv"
    elsif is_cs?
      "cs"
    elsif is_evcs?
      "evcs"
    elsif is_ev?
      "ev"
    elsif is_ov?
      "ov"
    end
  end
end


