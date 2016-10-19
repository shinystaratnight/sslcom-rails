class Capybara::Session
  # If form submit button is hidden or is not a true button or not easily accessible.
  def submit(element)
    Capybara::RackTest::Form.new(driver, element.native).submit({})
  end
end
