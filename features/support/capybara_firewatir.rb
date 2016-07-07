def get_element(element, attribute, attribute_val)
  if is_capybara?
    case element
      when /radio/, /checkbox/
        element="input"
        page.first(:xpath, "//#{element}[@#{attribute}='#{attribute_val}']")
      when /text_field/
        %w(input textarea).map do |text_elem|
          page.first(:xpath, "//#{text_elem}[contains(@#{attribute}, \'#{attribute_val}\')]")
        end.compact.last
    end
  else
    @browser.send(element.intern, attribute.intern, Regexp.new(attribute_val))
  end
end

def set_element(element, attribute, attribute_val, value)
  elem=get_element(element, attribute, attribute_val)
  is_capybara? ? elem.set(value) : elem.send(element.intern, attribute.intern, Regexp.new(attribute_val)).value = value
end

def goto(path)
  lambda{|x|is_capybara? ? visit(x) : @browser.goto(APP_URL+x)}.(path)
end

def fill_text(key,value)
  if is_capybara?
    case key
    when /country\z/, /credit_card\z/, /expiration_(month|year)\z/
      select value, from: key
    else
      fill_in(key, with: value)
    end
  else
    case key
    when /country\z/, /credit_card\z/, /expiration_[month|year]\z/
      @browser.select_list(:id, key).set value
    else
      @browser.text_field(:id, key).value = value
    end
  end
end

def url_should_include(text)
  (is_capybara? ? current_path : @browser.url).should include(text)
end

def should_have(text)
  (is_capybara? ? page : @browser.text).should have_content(text)
end

def handle_js_confirm(accept=true)
  page.evaluate_script "window.original_confirm_function = window.confirm"
  page.evaluate_script "window.confirm = function(msg) { return #{!!accept}; }"
  yield
ensure
  page.evaluate_script "window.confirm = window.original_confirm_function"
end