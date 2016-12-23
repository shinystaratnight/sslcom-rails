module LayoutsHelper
  def is_on?(model,current_slug={})
    current_page?(eval("#{model}_path(#{current_slug})")) ||
      (current_page?(eval("search_#{model}_path(#{current_slug})")) if Rails.application.routes.url_helpers.respond_to?("search_#{model}_path"))
  end
end
