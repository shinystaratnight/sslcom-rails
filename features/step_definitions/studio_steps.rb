When /\Ahe selects some files for uploading\z/ do
  file = "/home/sysadmin/Videos/Videos.zip"
  @browser.file_field(:id, "multi_upload").set file
  lambda {
    @browser.button(:id, "upload_clips").click
  }.should change(User.find_by_login_slug("aaron").releases, :count).by(2)
end

When /\A['"]([^'"]*)['"] selects some files for uploading\z/ do |user|
  file = "/home/sysadmin/Videos/Videos.zip"
  @browser.file_field(:id, "multi_upload").set file
  lambda {
    @browser.button(:id, "upload_clips").click
  }.should change(User.find_by_login_slug("aaron").releases, :count).by(2)
end