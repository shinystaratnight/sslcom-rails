class Performance < SitePrism::Page
  def calculate_page_load(start_time, milliseconds_timeout)
    end_time = Time.current
    dif = end_time - start_time
    milliseconds = (1000 * dif).to_i
    puts "#{milliseconds} milliseconds to render the Validations page"
    raise "It took #{milliseconds} milliseconds to render the Validations page" unless milliseconds < milliseconds_timeout
  end
end
