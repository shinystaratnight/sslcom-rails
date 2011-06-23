class OtherPartyValidationRequest < OtherPartyRequest
  DCV_SECTION = "dcv"
  DOCUMENTS_SECTION = "documents"
  BOTH_SECTIONS = "both"

  preference  :show_order_number, :default=>false
  preference  :sections, :string, :default=>BOTH_SECTIONS
end