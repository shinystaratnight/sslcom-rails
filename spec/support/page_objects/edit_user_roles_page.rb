class EditUserRolesPage < SitePrism::Page
  element :installer_checkbox, '#user_role_ids_9'
  element :owner_checkbox, '#user_role_ids_3'
  element :super_user_checkbox, '#user_role_ids_5'
  element :submit_button, '#next_submit'

  expected_elements :installer_checkbox, :owner_checkbox, :submit_button

  def select_ssl_account
    find('.select2-search').click
  end
end
