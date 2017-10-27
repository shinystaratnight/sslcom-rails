class Api::V1::BaseSerializer
  include JSONAPI::Serializer

  def type
    object.class.name.demodulize.singularize
  end
  
  def format_name(attribute_name)
    attribute_name.to_s
  end

  def relationship_self_link(attribute_name); end

  def relationship_related_link(attribute_name); end

  def self_link; end
end