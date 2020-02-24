# frozen_string_literal: true

class ApiCredentialDecorator < Draper::Decorator
  include Draper::LazyHelpers
  delegate_all

  def role_names
    return '' if object.role_ids.blank? || object.role_ids.empty?

    Role.find(role_ids).map(&:name).join(', ')
  end
end
