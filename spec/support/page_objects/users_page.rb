class UsersPage < SitePrism::Page
  set_url '/users'

  element :search_button, 'input[value="search"]'
  element :owner_link, 'a', text: 'owner'
end
