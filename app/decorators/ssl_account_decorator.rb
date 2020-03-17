# frozen_string_literal: true

class SslAccountDecorator < Draper::Decorator
  delegate_all

  def has_role?(role)
    role_id = Role.get_role_id(role)
    object.roles.split(',').map(&:to_i).include? role_id
  end
end
