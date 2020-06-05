require 'active_support/concern'

module SerializerHelper
  extend ActiveSupport::Concern

  def serialize_model(model, options = {})
    options[:namespace] = Api::V1
    options[:is_collection] = false
    serialize_resource(model, options)
  end

  def serialize_models(models, options = {})
    options[:namespace] = Api::V1
    options[:is_collection] = true
    serialize_resource(models, options)
  end

  def serialize_object_errors(object)
    JSONAPI::Serializer.serialize_errors(object.errors)
  end

  def serialize_resource(resource, options)
    JSONAPI::Serializer.serialize(resource, options)
  end
end
