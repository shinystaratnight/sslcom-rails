class Search < SitePrism::Page
  element :search_field, '#search'

  expected_elements :search_field, :search_button
end
