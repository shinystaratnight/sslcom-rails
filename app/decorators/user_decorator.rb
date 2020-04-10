# frozen_string_literal: true

class UserDecorator < ApplicationDecorator
  delegate_all

  def has_role?(role)
    role_id = Role.get_role_id(role)
    object.roles.split(',').map(&:to_i).include? role_id
  end

  def thumbnail
    if Rails.env.test?
      h.fa_icon('user-circle', size: '4x')
    elsif object.avatar.file?
      h.image_tag(object.authenticated_avatar_url({ style: :thumb }), alt: object.login, class: 'xs-avatar')
    else
      h.fa_icon('user-circle', size: '4x')
    end
  end

  def full_avatar
    if Rails.env.test?
      h.fa_icon('user-circle', size: '7x')
    elsif object.avatar.file?
      h.image_tag(object.authenticated_avatar_url({ style: :thumb }), alt: object.login, class: 'avatar')
    else
      h.fa_icon('user-circle', size: '7x')
    end
  end
end
