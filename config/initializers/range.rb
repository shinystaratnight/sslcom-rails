Range.class_eval do
  def to_friendly
    to_s.gsub "..", "-"
  end
end