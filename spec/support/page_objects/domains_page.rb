class DomainPage < SitePrism::Page
  set_url '/domains'

  element :add_button, '#d_name_action_add'
  element :domains_field, '#domain_names'
  element :save_button, '.btn-save-domains'
end
