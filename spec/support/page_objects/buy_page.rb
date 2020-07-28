class BuyPage < SitePrism::Page
  set_url '/certificates'

  elements :buy_buttons, "img[title='click to buy this certificate']"
end
