# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'string'
  require 'object'

  # from Dan Webb's MinusMOR plugin
  def js(data)
    if data.respond_to? :to_json
      data.to_json
    else
      data.inspect.to_json
    end
  end

  # from Dan Webb's MinusMOR plugin
  # enhanced with ability to detect partials with template format, i.e.: _post.html.erb
  def partial(name, options={})
    old_format = self.template_format
    self.template_format = :html
    js render({ :partial => name }.merge(options))
  ensure
    self.template_format = old_format
  end

  def logged_in_or_front_page
    current_user && !current_page?(:controller=>:site, :action=>:index)
  end

  def photo_path(photo)
    if photo.is_a? Photo
      user_photo_path(photo.user, photo)
    elsif photo.is_a? StudioPhoto
      studio_studio_photo_path(photo.studio, photo)
    elsif photo.is_a? AffiliatePhoto
      affiliate_affiliate_photo_path(photo.affiliate, photo)
    end
  end

  def image_url(source, timestamp=true)
    abs_path = image_path(source)
    unless abs_path =~ /\Ahttp/
      abs_path = "http#{'s' if request.protocol =~ /https/}://#{request.host_with_port}#{abs_path}"
    end
    if timestamp
      abs_path
    else
      abs_path.split('?')[0]
    end
  end

  def selector(obj)
    js "##{dom_id(obj)}"
  end

  def show_studio_only?
    (@studio && Studio.exists?(@studio) &&
      (current_page?(manage_video_sets_studio_releases_path(@studio)) ||
        current_page?(manage_studio_releases_path(@studio)) ||
        current_page?(studio_path(@studio)) ||
        current_page?(studio_releases_path(@studio)))) ||
    (@release && Release.exists?(@release) &&
      current_page?(edit_release_path(@release.studio, @release)))
  end

  def text_field_for(form, field,
      size=HTML_TEXT_FIELD_SIZE,
      maxlength=DB_STRING_MAX_LENGTH, options = {})
    form_field = form.text_field field, :size => size, :maxlength => maxlength
    label = form.label(field, "#{'*' if options.delete(:required)}#{field.humanize}:".gsub(/\b\w/) {|s| s.upcase }) unless options.delete(:no_label)
    append = yield if block_given?
    create_tags label, form_field, options, append
  end

  def check_box_for(form, field, yes="1", no="0", options={})
    form_field = form.check_box field, options, yes, no
    label = form.label(field, "#{field.humanize}:".gsub(/\b\w/) {|s| s.upcase }) unless options.delete(:no_label)
    append = yield if block_given?
    create_tags label, form_field, options, append
  end

  def country_select_field_for(form, field, priority_countries = nil, options = {}, html_options = {})
    #TODO needs fixing
    #form_field = localized_country_select form.object_name, field, priority_countries, options, html_options
    form_field = country_select form.object_name, field, priority_countries, options, html_options
    label = content_tag("label", "#{'*' if options.delete(:required)}#{field.humanize}:".gsub(/\b\w/) {|s| s.upcase }, :for => field) unless options.delete(:no_label)
    append = yield if block_given?
    create_tags label, form_field, options, append
  end

  def credit_card_select_field_for(form, field, options = {}, html_options = {})
    form_field = form.select field, BillingProfile::CREDIT_CARDS, options, html_options
    label = content_tag("label", "#{'*' if options.delete(:required)}#{field.humanize}:".gsub(/\b\w/) {|s| s.upcase }, :for => field) unless options.delete(:no_label)
    append = yield if block_given?
    create_tags label, form_field, options, append
  end

  def description_or_tagline(user)
    user.is_a?(User)? user.description : user.tagline
  end

  def display_name(user)
    user.is_a?(User)? user.login : user.display_name
  end

  def tree_list(channel)
    base_finder = (filter_audience_type.blank?)? Release : Release.
      scoped_by_audience_type(filter_audience_type)
    @release_count = base_finder.all
    @tree="<ul>"
    channels = channel.camelcase.constantize.all :conditions => {:parent_id => nil}
    channels.sort_by(&:name).each_with_object(@tree) do |channel, tree|
      tree << ordered_list_for_tree(channel)
    end
    @tree<<"</ul>"
  end

  def ordered_list_for_tree(channel)
    returning "" do |tree|
      unless channel.root?
        tree << "<li>" << link_to(channel.name << ' (' << @release_count.select{|r|r.channel_id==channel.id}.size.to_s << ')', channel_path(channel)) << "</li>"
      else
        tree << "<li>" << link_to(channel.name << ' (' << @release_count.select{|r|[r.channel_id, r.channel.parent_id].include? channel.id }.size.to_s << ')', channel_path(channel))
        unless channel.children.blank?
          tree << "<ul>"
          channel.children.each_with_object(tree) do |child, tree|
            tree << ordered_list_for_tree(child)
          end
          tree << "</ul>"
        end
        tree << "</li>"
      end
    end
  end

  def select_field_for(form, field, choices, options = {}, html_options = {})
    form_field = form.select field, choices, options, html_options
    label = content_tag("label", "#{field.humanize}:".gsub(/\b\w/) {|s| s.upcase }, :for => field) unless options.delete(:no_label)
    append = yield if block_given?
    create_tags label, form_field, options, append
  end

  def add_to_cart_button(item)
    if SERVER_SIDE_CART
      button_to_function "Add to cart", remote_function(:url => {:controller =>
            :orders, :action => :add, :id => item.model_and_id}), ({:disabled =>
            "disabled"} if cart_items.include? item )
    else
      button_to_function("Add to cart", :id => item.model_and_id,
        :class => "add_to_cart_button", :disabled => (!current_user.blank? &&
            current_user.owns_release(item))? true : false)
    end
  end

  def remove_from_cart_link(item)
    if SERVER_SIDE_CART
      link_to_remote 'Remove', :url => {:controller => :orders, :action => :remove, :id => item.model_and_id}
    else
      link_to_function "Remove", :id => item.model_and_id, :class => "remove_from_cart_link"
    end
  end

  #Copied from /vendor/plugins/community_engine/engine_plugin/tiny_mce/lib/tiny_mce_helper.rb
  #because it somehow skips loading tiny_mce_helper
  def tiny_mce_init(options = @tiny_mce_options)
    options ||= {}
    default_options = {:mode => 'textareas',
                       :theme => 'simple'}
    options = default_options.merge(options)
    TinyMCE::OptionValidator.plugins = options[:plugins]
    tinymce_js = "tinyMCE.init({\n"
    i = 0
    options.stringify_keys.sort.each do |pair|
      key, value = pair[0], pair[1]
      raise InvalidOption.new("Invalid option #{key} passed to tinymce") unless TinyMCE::OptionValidator.valid?(key)
      tinymce_js += "#{key} : "
      case value
      when String, Symbol, Fixnum
        tinymce_js += "'#{value}'"
      when Array
        tinymce_js += '"' + value.join(',') + '"'
      when TrueClass
        tinymce_js += 'true'
      when FalseClass
        tinymce_js += 'false'
      else
        raise InvalidOption.new("Invalid value of type #{value.class} passed for TinyMCE option #{key}")
      end
      (i < options.size - 1) ? tinymce_js += ",\n" : "\n"
      i += 1
    end
    tinymce_js += "\n});"
    javascript_tag tinymce_js
  end
  alias tiny_mce tiny_mce_init

  def using_tiny_mce?
    !@uses_tiny_mce.nil?
  end

  def javascript_include_tiny_mce
    javascript_include_tag RAILS_ENV == 'development' ? "tiny_mce/tiny_mce_src" : "tiny_mce/tiny_mce", :plugin => "community_engine"
  end

  def javascript_include_tiny_mce_if_used
    javascript_include_tiny_mce if @uses_tiny_mce
  end

  private

  def create_tags(label, form_field, options, append)
    tag_class = options.delete :class
    required = options.delete :required
    format = options.delete :format
    asterisk = (required)?"*":""
    append ||= ""
    case format
      when /table/
        content_tag("th", "#{label}#{asterisk}") + content_tag("td","#{form_field}#{append}")
      when /no_div/
        "#{label}#{asterisk} #{form_field}#{append}"
      else
        content_tag("div", "#{label}#{asterisk} #{form_field}#{append}", :class => tag_class)
    end
  end

  def srp_link
    link_to "SSL Reseller Program", details_resellers_url
  end

  def link_to_remove_fields(name, f)
   f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end

  def order_progress_indicator(page, certificate)
    process = @certificate_order.preferred_payment_order=='prepaid' ?
      @certificate_order.prepaid_signup_process(certificate) :
      @certificate_order.signup_process(certificate)
    padding = case process
    when CertificateOrder::EXPRESS_SIGNUP_PROCESS
      'padding: 0 4em'
    when CertificateOrder::FULL_SIGNUP_PROCESS
      'padding: 0 1.35em'
    when CertificateOrder::PREPAID_FULL_SIGNUP_PROCESS
      'padding: 0 2.4em'
    when CertificateOrder::PREPAID_EXPRESS_SIGNUP_PROCESS
      'padding: 0 6.5em'
    end
    render(:partial => '/shared/form_progress_indicator',
      :locals => {:pages=>[process[:pages], page],
        :options=>{:li_style=>padding}})
  end

  def is_public_index_page?
    current_page?(:controller=>:site, :action=>:index) ||
    current_page?(:controller=>:site, :action=>:reseller)
  end

  # If the current user meets the given privilege, permitted_to? returns true
  # and yields to the optional block.  The attribute checks that are defined
  # in the authorization rules are only evaluated if an object is given
  # for context.
  #
  # Examples:
  #     <% permitted_to? :create, :users do %>
  #     <%= link_to 'New', new_user_path %>
  #     <% end %>
  #     ...
  #     <% if permitted_to? :create, :users %>
  #     <%= link_to 'New', new_user_path %>
  #     <% else %>
  #     You are not allowed to create new users!
  #     <% end %>
  #     ...
  #     <% for user in @users %>
  #     <%= link_to 'Edit', edit_user_path(user) if permitted_to? :update, user %>
  #     <% end %>
  #
  # To pass in an object and override the context, you can use the optional
  # options:
  #     permitted_to? :update, user, :context => :account
  #
  def permitted_to? (privilege, object_or_sym = nil, options = {}, &block)
    controller.permitted_to?(privilege, object_or_sym, options, &block)
  end

  # While permitted_to? is used for authorization in views, in some cases
  # content should only be shown to some users without being concerned
  # with authorization.  E.g. to only show the most relevant menu options
  # to a certain group of users.  That is what has_role? should be used for.
  #
  # Examples:
  #     <% has_role?(:sales) do %>
  #     <%= link_to 'All contacts', contacts_path %>
  #     <% end %>
  #     ...
  #     <% if has_role?(:sales) %>
  #     <%= link_to 'Customer contacts', contacts_path %>
  #     <% else %>
  #     ...
  #     <% end %>
  #
  def has_role? (*roles, &block)
    controller.has_role?(*roles, &block)
  end

  # As has_role? except checks all roles included in the role hierarchy
  def has_role_with_hierarchy?(*roles, &block)
    controller.has_role_with_hierarchy?(*roles, &block)
  end

  def message_for_item(message, item = nil)
    return message unless item
    if item.is_a?(Array)
      message % link_to(*item)
    else
      message % item
    end
  end
end
