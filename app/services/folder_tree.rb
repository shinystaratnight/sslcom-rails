class FolderTree
  attr_reader :full_tree, :selected_ids

  def initialize(ssl_account_id, folder, tree_type='folders_index', selected_ids=nil)
    @full_tree = []
    @selected_ids = selected_ids.is_a?(Array) ? selected_ids : [selected_ids].compact
    @folder = folder
    @full_tree = build_subtree(@folder, tree_type)
  end

  def build_subtree(folder, tree_type)
    children = folder.children ? folder.children.inject([]) {|all, child| all << build_subtree(child, tree_type) } : []
    co_children = tree_type == 'co_folders_index' ? [] : build_cert_orders(folder)
    return {
      id: get_id_format(folder),
      text: folder.name,
      icon: get_icon(folder),
      type: 'folder',
      li_attr: get_li_attr(folder),
      data: get_data(folder, tree_type),
      state: { opened: false },
      children: (children + co_children).flatten
    }
  end

  def build_cert_orders(folder)
    files = []
    cos = folder.certificate_orders.uniq
    if cos.any?
      cos.each do |co|
        files << {
          id: get_id_format(co),
          text: co.ref,
          icon: get_icon(co),
          type: 'file',
          li_attr: get_li_attr(co),
          state: { opened: false }
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

  def co_common_name(co)
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
    "#{cn} (#{co.ref})"
  end
end
