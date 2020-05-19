require 'rails_helper'

RSpec.describe 'UserAvatars', type: :feature do
  describe 'Uploading User Avatars' do
    it 'allows user`s to upload avatars' do
      as_user(create(:user, :owner)) do
        visit '/account'
        click_on 'Add photo'
        attach_file 'file', Rails.root.join('spec/fixtures/images/user_avatar.jpeg')
        expect(page).to have_content('Loading...')
      end
    end
  end
end
