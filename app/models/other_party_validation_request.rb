class OtherPartyValidationRequest < OtherPartyRequest
  DCV_SECTION = "dcv"
  DOCUMENTS_SECTION = "documents"
  BOTH_SECTIONS = "both"

  preference  :show_order_number, :default=>false
  preference  :sections, :string, :default=>BOTH_SECTIONS

  after_create do |o|
    OtherPartyRequestMailer.request_validation(o).deliver
  end

  def allowed(email)
    email_addresses.include?(email)
  end

  def hide_dcv?
    preferred_sections==DOCUMENTS_SECTION
  end

  def hide_documents?
    preferred_sections==DCV_SECTION
  end

  def hide_both?
    preferred_sections==BOTH_SECTIONS
  end

end