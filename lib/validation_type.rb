module ValidationType
  def validation_type
    if is_dv?
      "dv"
    elsif is_ev?
      "ev"
    elsif is_ov?
      "ov"
    end
  end
end


