require 'rails_helper'

RSpec.describe 'UserAvatars', type: :feature do
  let!(:user) {create(:user, :owner)}

  describe 'Uploading User Avatars' do
    xit 'allows user`s to upload avatars', js: true do
      as_user(create(:user, :owner)) do
        visit '/account'
        click_on 'Add photo'
        attach_file 'file', Rails.root.join('spec/fixtures/images/user_avatar.jpeg')
        expect(page).to have_content('Loading...')
      end
      login_page = LoginPage.new
      login_page.login_with(user)
      account_page = AccountPage.new
      account_page.load
      account_page.add_photo.click
      attach_file('Upload Your File', Rails.root + 'spec/fixtures/user_avatar.jpeg',  visible: false)
      account_page.wait_until_preview_photo_visible
      click_button 'Close'
    end
  end
end
