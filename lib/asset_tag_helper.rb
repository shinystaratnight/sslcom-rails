# Extend img tag to use the alt text for the title attribute if alt is present & title is empty (for SEO)
ActionView::Helpers::AssetTagHelper.module_eval do
  alias_method :orig_image_tag, :image_tag
  def image_tag(source, options = {})
    if options[:alt] && !options[:title]
      options[:title] = options[:alt]
    end
    return orig_image_tag(source, options)
  end
end

ActionView::Helpers::UrlHelper.module_eval do
  alias_method :orig_url_for, :url_for
  def url_for(options={})
    options.reverse_merge!({subdomain: false}) if options.is_a?(Hash)
    return orig_url_for(options)
  end
end