# clean_to_json.rb
module CleanToJson
  def as_json(options = nil)
    super(options).tap do |json|
      json.delete_if{|k,v| v.nil?}.as_json unless options.try(:delete, :null)
    end
  end
end
