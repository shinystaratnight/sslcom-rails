require 'carrierwave/test/matchers'
require 'test_helper'

describe AvatarUploader do
  include CarrierWave::Test::Matchers

  let(:user) { create(:user) }
  let(:uploader) { AvatarUploader.new(user, :avatar) }

  before do
    AvatarUploader.enable_processing = true
    path = Rails.root.join('test/factories/images/idris.jpg')
    File.open(path) { |f| uploader.store!(f) }
  end

  after do
    AvatarUploader.enable_processing = false
    uploader.remove!
  end

  it "scales down a image to be exactly 64 by 64 pixels for thumb" do
    assert_be_no_larger_than(uploader.thumb.current_path, 64, 64)
  end

  it "scales down a landscape image to be exactly 200 by 200 pixels for standard" do
    assert_be_no_larger_than(uploader.standard.current_path, 200, 200)
  end

  it "scales down a landscape image to be exactly 400 by 400 pixels large" do
    assert_be_no_larger_than(uploader.large.current_path, 400, 400)
  end

  it "makes the image read and writable to the owner and not executable" do
    assert_have_permissions(uploader.current_path, '644')
  end

  it "has the correct format" do
    assert_format(uploader.current_path, 'JPEG')
  end
end
