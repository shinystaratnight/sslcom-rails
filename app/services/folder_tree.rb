class FolderTree
  attr_reader :full_tree, :selected_ids

  def initialize(ssl_account_id, folder, selected_ids=nil)
    @full_tree = []
    @selected_ids = selected_ids.is_a?(Array) ? selected_ids : [selected_ids].compact
    @folder = folder
    @full_tree = build_subtree(@folder)
  end

  def build_subtree(folder)
    children = folder.children ? folder.children.inject([]) {|all, child| all << build_subtree(child) } : []
    co_children = build_cert_orders(folder)
    return {
      id: get_id_format(folder),
      text: folder.name,
      icon: get_icon(folder),
      type: 'folder',
      li_attr: get_li_attr(folder),
      data: get_data(folder),
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
      elsif object.archive?
        'fa fa-archive'
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
      elsif object.archive?
        'jstree-folder-archive'
      else
        'jstree-folder-normal'
      end
    else
      'jstree-co'
    end
    return { class: klass }
  end

  def get_data(folder)
    return {
      archived: folder.archive?,
      default: folder.default?
    }
  end
end
