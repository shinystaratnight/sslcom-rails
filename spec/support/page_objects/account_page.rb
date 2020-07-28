class AccountPage < SitePrism::Page
  set_url '/account'
  element :add_photo, '#add-avatar'
  element :preview_photo, '#preview'
  element :avatar_image, '.avatar'

  expected_elements :add_photo
end
