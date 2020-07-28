class Navbar < SitePrism::Page
  element :buy, '#manage_certificates'
  element :dashboard, '#dashboard a'
  element :validations, '#manage_validations'
  element :orders, '#manage_certificate_orders'
  element :transactions, '#manage_orders'
  element :teams, '#manage_teams'
  element :users, '#manage_certificates'
  element :cdn, '#manage_cdns'
  element :settings, '#manage_settings'
end
