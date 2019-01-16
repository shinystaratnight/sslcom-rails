class FolderTree
  attr_reader :full_tree, :selected_ids

  def initialize(params)
    @full_tree = []
    @selected_ids = params[:selected_ids].is_a?(Array) ? params[:selected_ids] : [params[:selected_ids]].compact
    @folder = params[:folder]
    @certificate_order_ids = params[:certificate_order_ids]
    @filtered_folder_ids = params[:folder_ids]
    @full_tree = build_subtree(@folder, params[:tree_type])
  end

  def build_subtree(folder, tree_type)
    Rails.cache.fetch("#{folder.cache_key}/#{tree_type}/build_subtree") do
      folder_children = get_folder_children(folder)
      children = folder_children ? folder_children.inject([]) {|all, child| all << build_subtree(child, tree_type) } : []
      co_children = if %w{co_folders_index co_folders_index_modal}.include?(tree_type)
                      []
                    else
                      build_cert_orders(folder)
                    end

      data = get_data(folder, tree_type)

      return {
          id:       get_id_format(folder),
          icon:     get_icon(folder),
          text:     get_folder_name(folder, tree_type, data),
          type:     'folder',
          li_attr:  get_li_attr(folder),
          data:     data,
          state:    { opened: false },
          children: (children + co_children).flatten
      }
    end
  end

  def get_folder_children(folder)
    filter_children = folder.children
    if filter_children.any? && @filtered_folder_ids && @filtered_folder_ids.any?
      filter_children = filter_children.where(id: @filtered_folder_ids)
    end
    filter_children
  end

  def get_folder_name(folder, tree_type, options=nil)
    if tree_type == 'co_folders_index'
      "#{folder.name} <span class='folder-co-count'>#{options[:certificate_orders_count]}</span>".html_safe
    else
      folder.name
    end
  end

  def build_cert_orders(folder)
    files = []
    cos = folder.cached_certificate_orders

    if @certificate_order_ids && @certificate_order_ids.any?
      cos = cos.where(id: @certificate_order_ids)
    end
      
    if cos.uniq.any?
      cos.each do |co|
        files << {
          id: get_id_format(co),
          text: co.ref,
          icon: get_icon(co),
          type: 'file',
          li_attr: get_li_attr(co),
          state: { opened: false },
          data: get_data_certificate(co)
        }
      end
    end
    files
  end

  def get_icon(object)
    if object.is_a?(Folder)
      if object.default?
        'fa fa-certificate'
      elsif object.archived?
        'fa fa-archive'
      elsif object.expired?
        'fa fa-history'
      elsif object.active?
        'fa fa-gear'
      elsif object.revoked?
        'fa fa-warning'
      else
        'jstree-folder'
      end
    else
      'jstree-file'
    end
  end

  def get_id_format(object)
    object.is_a?(Folder) ? "#{object.id}_folder" : "#{object.ref}_cert"
  end

  def get_li_attr(object)
    if object.is_a?(Folder)
      klass = if object.default?
        'jstree-folder-default'
      elsif object.archived?
        'jstree-folder-archive'
      elsif object.active?
        'jstree-folder-active'
      elsif object.expired?  
        'jstree-folder-expired'  
      else
        'jstree-folder-normal'
      end
    else
      'jstree-co'
    end
    return { class: klass }
  end

  def get_data(folder, tree_type=nil)
    data = {
      archived: folder.archived?,
      default: folder.default?,
      expired: folder.expired?
    }
    if tree_type && tree_type == 'co_folders_index'
      cos = get_data_certificates(folder)
      data = data.merge(cos);
    end
    return data
  end

  def get_data_certificates(folder)
    data = {certificate_orders: []}
    list = folder.certificate_orders.uniq
    folder.certificate_orders.uniq.each do |co|
      data[:certificate_orders].push co_common_name(co)
    end
    data.merge(certificate_orders_count: list.count)
  end

  def get_data_certificate(co)
    return {
      ref: co.ref,
      subject: co_common_name(co, true),
      status: co_status(co),
      expires: co_expires_on(co)
    }
  end

  def co_status(co)
    return if co.certificate_content.blank?
    certificate_content = co.certificate_content
    if co && certificate_content.new?
      if co.is_expired?
        'expired'
      else
        co.certificate.admin_submit_csr? ? 'info required' : 'waiting for csr'
      end
    elsif certificate_content.expired?
      'expired'
    elsif certificate_content.preferred_reprocessing?
      'reprocess requested'
    else
      case certificate_content.workflow_state
        when 'csr_submitted' then 'info required'
        when 'info_provided' then 'contacts required'
        when 'reprocess_requested' then 'csr required'
        when 'contacts_provided' then 'validation required'
        else
          certificate_content.workflow_state.to_s.titleize.downcase
      end
    end
  end

  def co_expires_on(co)
    return '' if co.certificate_content.csr.blank?
    cc = co.certificate_content
    if cc.new? || cc.csr.signed_certificate.blank? ||
      cc.csr.signed_certificate.expiration_date.blank?
        ''
    else
      cc.csr.signed_certificate.expiration_date.strftime("%b %d, %Y")
    end
  end

  def co_common_name(co, cn_only=false)
    if co.is_expired_credit?
      cn = "expired certificate"
    else
      cn = if co.is_unused_credit?
        "credit - #{co.certificate.description['certificate_type']} certificate"
      else
        if co.certificate.is_code_signing?
          co.registrant.try(:company_name) || "#{co.certificate.description['certificate_type']} certificate"
        else
          co.common_name
        end
      end
    end
    cn_only ? cn : "#{cn} (#{co.ref})"
  end
end
