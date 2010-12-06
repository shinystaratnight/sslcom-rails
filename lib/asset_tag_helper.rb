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