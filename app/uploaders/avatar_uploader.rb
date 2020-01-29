# frozen_string_literal: true

class AvatarUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{Rails.env}/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    "#{Rails.root}/tmp/uploads/#{Rails.env}/images"
  end

  # Create different versions of your uploaded files:
  version :thumb do
    process resize_to_fit: [64, 64]
  end

  version :standard do
    process resize_to_fit: [200, 200]
  end

  version :large do
    process resize_to_fit: [400, 400]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w[jpg jpeg gif png]
  end
end
