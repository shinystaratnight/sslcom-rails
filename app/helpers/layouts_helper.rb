module LayoutsHelper
  def is_on?(model)
    current_page?("#{model}".to_sym) || current_page?("search_#{model}".to_sym)
  end
end
