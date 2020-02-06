# frozen_string_literal: true

class UserSerializer
  include FastJsonapi::ObjectSerializer

  link :standard_avatar_url do |object|
    object.authenticated_avatar_url(style: :standard)
  end

  link :thumbnail_avatar_url do |object|
    object.authenticated_avatar_url(style: :thumb)
  end

  link :large_avatar_url do |object|
    object.authenticated_avatar_url(style: :large)
  end
end
