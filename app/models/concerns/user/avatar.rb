# frozen_string_literal: true

module Concerns
  module User
    module Avatar
      extend ActiveSupport::Concern

      included do
        has_attached_file :avatar, s3_protocol: 'http', url: '/:class/:id/:attachment/:style.:extension', path: ':id_partition/:style.:extension', s3_permissions: :private, bucket: ENV['S3_AVATAR_BUCKET_NAME'], styles: {
          thumb: '100x100>',
          standard: '200x200#',
          large: '300x300>'
        }

        validates_attachment_content_type :avatar, content_type: %r{\Aimage/.*\z}
      end
    end
  end
end
