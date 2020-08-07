class UserSerializer < ActiveModel::Serializer
  attribute :standard_avatar_url do
    object.authenticated_avatar_url(style: :standard)
  end

  attribute :thumbnail_avatar_url do
    object.authenticated_avatar_url(style: :thumb)
  end

  attribute :large_avatar_url do
    object.authenticated_avatar_url(style: :large)
  end
end
