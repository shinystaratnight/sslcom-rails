# frozen_string_literal: true

class ApiCredentialDecorator < ApplicationDecorator
  delegate_all

  def role_names
    roles.map(&:name)
  end

  def role_names_for_display
    roles.map(&:name).join(', ')
  end

  def roles
    if object.roles.nil?
      Role.none
    else
      Role.find(object.roles.scan(/\d/).map(&:to_i))
    end
  end

  def role_name_copy_link
    render partial: 'shared/copy_button', locals: { content: role_names_for_display } unless role_names.empty?
  end
end
