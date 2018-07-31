$(function($) {
  var errorsExist = false;

  folderClearErrors = function() {
    errorsExist =  false;
  };

  getJstreeRef = function() {
    var folder_id = $('#folders-tree').length ? '#folders-tree' : '#folders-tree-co';
    return $(folder_id).jstree(true);
  };

  certificateOrder = function(node) {
    str_id = node.id ? node.id : node;
    return (str_id.split('_').pop() == 'cert');
  };

  fetchFolderId = function(node) {
    str = (typeof(node) === typeof(String())) ? node : node.node.id;
    return str.replace('_folder', '');
  }

  fetchCertOrderId = function(node) {
    str = (typeof(node) === typeof(String())) ? node : node.node.id;
    return str.replace('_cert', '');
  }

  folderParseErrors = function(json) {
    var errors_output = '';
    if ( json.responseText.includes("<html") ) {
      errors_output += "Something went wrong, please try again";
    } else {
      var errors = JSON.parse(json.responseText)
      for (var key in errors) {
        if (errors.hasOwnProperty(key)) {
          errors_output += key.replace('_', ' ') + ": " + errors[key].join(', ') + ". ";
        }
      }
    }
    alert(errors_output);
  };

  folderCreateJstree = function() {
    var ref = getJstreeRef(),
      sel = ref.get_selected(true);

    if (!sel.length) { return false; }
    sel = sel[0];
    if (certificateOrder(sel)) {
      sel = ref.create_node(ref.get_node(sel.parent, true), { "type":"folder" });
    } else {
      sel = ref.create_node(sel, { "type":"folder" });
    }
    if (sel) {
      ref.edit(sel, 'new_folder', function(data) {
        resp = folderCreate(data.parent.split('_').shift(), data.text);
        if (!resp) { ref.delete_node(sel); }
        return resp;
      });
    }
  };

  folderRenameJstree = function() {
    var ref = getJstreeRef(),
      sel = ref.get_selected();
    if (!sel.length) { return false; }
    sel = sel[0];
    if (sel && !certificateOrder(sel)) {
      ref.edit(sel, sel.text, function(data) {
        resp = folderRename(data.id.split('_').shift(), data.text);
        return resp;
      });
    }
  };

  folderDeleteJstree = function() {
    var ref = getJstreeRef(),
      sel = ref.get_selected(true);
    if (!sel.length) { return false; }

    if (sel) {
      resp = folderDelete(
        ref.get_selected(true)[0].id.split('_').shift()
      );
      if (resp) { ref.delete_node(sel); }
    }
  };

  folderDefaultJstree = function() {
    var ref = getJstreeRef(),
      sel = ref.get_selected(true);
    if (!sel.length) { return false; }

    if (sel) {
      resp = folderDefault(
        ref.get_selected(true)[0].id.split('_').shift()
      );
      if (resp) { ref.load_all(); }
    }
  };

  folderAction = function(form, type, concat='') {
    $.ajax({
      type: type,
      url: form.attr('action'),
      data: form.serialize().concat(concat),
      dataType: 'JSON'
    }).success(function() {
      errorsExist = false;
    }).error(function(json) {
      errorsExist = true;
      folderParseErrors(json);
    });
  };

  folderDefault = function(node_id) {
    var form = $('#frm-folder-edit');
    form.find('#folder_id').val(node_id);
    updateFolderId(form, node_id);
    folderAction(form, 'PUT', "&update_type=default");
    return !errorsExist;
  };

  folderDelete = function(node_id) {
    var form = $('#frm-folder-delete');
    form.find('#folder_id').val(node_id);
    updateFolderId(form, node_id);
    folderAction(form, 'DELETE');
    return !errorsExist;
  };

  folderCreate = function(parent_id, node_name) {
    var form = $('#frm-folder-create');
    form.find('#folder_parent_id').val(parent_id);
    form.find('#folder_name').val(node_name);
    folderAction(form, 'POST');
    return !errorsExist;
  };

  folderRename = function(node_id, node_name) {
    var form = $('#frm-folder-edit');
    form.find('#folder_id').val(node_id);
    form.find('#folder_name').val(node_name);
    updateFolderId(form, node_id);
    folderAction(form, 'PUT', "&update_type=rename");
    return !errorsExist;
  };

  nodeMoveJstree = function(node) {
    var node_id = node.node.id;
    if (node_id.includes('_folder')) {
      folderNodeMove(node);
    } else {
      coNodeMove(node);
    }
    return !errorsExist;
  };

  folderNodeMove = function(node) {
    var form = $('#frm-folder-edit'),
      node_id = fetchFolderId(node);
    form.find('#folder_id').val(node_id);
    form.find('#folder_parent_id').val(fetchFolderId(node.parent));
    updateFolderId(form, node_id);
    folderAction(form, 'PUT', "&update_type=move");
  };

  coNodeMove = function(node) {
    var form = $('#frm-folder-add-cert'),
      node_id = fetchCertOrderId(node);
    form.find('#folder_certificate_order_id').val(node_id);
    updateFolderId(form, fetchFolderId(node.parent));
    folderAction(form, 'PUT');
  };

  updateFolderId = function(form, folder_id) {
    cur_action = form.data('initial-action');
    new_action = decodeURIComponent(cur_action).replace('#', folder_id);
    form.attr('action', new_action);
  }

  $('#btn-folder-create').on('click', function(e) {
    e.preventDefault();
    folderCreateJstree();
  });

  $('#btn-folder-rename').on('click', function(e) {
    e.preventDefault();
    folderRenameJstree();
  });

  $('#btn-folder-destroy').on('click', function(e) {
    e.preventDefault();
    folderDeleteJstree();
  });

  $('#btn-folder-default').on('click', function(e) {
    e.preventDefault();
    folderDefaultJstree();
  });

  $('#folders-tree').on('move_node.jstree', function(e, node) {
    nodeMoveJstree(node);
  });

  var to = false;
  $('#folder-scan').keyup(function () {
    if(to) { clearTimeout(to); }
    to = setTimeout(function () {
      var search = $('#folder-scan').val();
      getJstreeRef().search(search);
    }, 250);
  });

  /*
   * Certificate Orders Index: Folders
   */
  var co_id = '#folders-tree-co';

  setSelectedCount = function(data='clear') {
    return $("#folders-selected-count").text(
      (data == 'clear' ? 0 : data.selected.length)
    );
  };
  
  setFilterParams = function(clear=false) {
    var checked = getJstreeRef().get_checked(),
      new_url = '',
      base_url = $('#btn-co-filter-by').attr('href').split('?')[0];
    
    if (clear) {
      new_url = base_url;
    } else {
      query = "?search=folder_ids:"
        + checked.join().split('_folder,').join().replace('_folder','');
      new_url = base_url + query;
    }
    $('#btn-co-filter-by').attr('href', new_url);
  };

  getCheckedCertOrders = function() {
    var cert_orders  = $('.chk-folder-add-co:checkbox:checked').map(function() {
      return this.id;
    }).get();
    return cert_orders;
  };

  addCertOrdersJstree = function() {
    var form = $('#frm-folder-add-certs'),
      node_id = fetchFolderId(getJstreeRef().get_checked()[0]);
    form.find("#folder_folder_certificate_order_ids").val(
      getCheckedCertOrders().join(',')
    );
    updateFolderId(form, node_id);
    form.submit();
  };

  $(co_id).on("check_node.jstree", function (e, data) {
    setSelectedCount(data);
    setFilterParams();
  });

  $(co_id).on("uncheck_node.jstree", function (e, data) {
    setSelectedCount(data);
    setFilterParams();
  });

  $('#btn-folder-uncheck').on('click', function(e) {
    e.preventDefault();
    getJstreeRef().uncheck_all();
    setSelectedCount();
    setFilterParams(true);
  });

  $('#btn-folder-closeall').on('click', function(e) {
    e.preventDefault();
    getJstreeRef().close_all();
  });

  $('#btn-folder-openall').on('click', function(e) {
    e.preventDefault();
    getJstreeRef().open_all();
  });

  $('#btn-co-filter-by').on('click', function(e) {
    if (getJstreeRef().get_checked().length == 0) {
      e.preventDefault();
      alert('Check at least one folder.');
    }
  });

  $('#btn-co-folders-addcert').on('click', function(e) {
    e.preventDefault();
    var selected = getJstreeRef().get_checked().length,
        selected_co = getCheckedCertOrders();
    
    if ( selected == 0) {
      alert('Check at least one folder.');
    } else if (selected > 1) {
      alert('You checked ' + selected + ' folders. Please select only one folder to move certificates.' );
    } else if (selected_co.length == 0) {
      alert('Select at least one certificate below to put in folder.' );
    } else {
      addCertOrdersJstree();
    }
  });
  
  $('#co-folder-column').on('click', function(e) {
    $('.chk-folder-add-co').click();
  });

  /*
   * Change Folder Modal
   */
  var co_id = '#folders-tree-modal',
    checked = [];
  
  addCertOrderJstree = function(folder_id) {
    var form = $('#frm-folder-add-cert');
    updateFolderId(form, fetchFolderId(folder_id));
  };

  // Can only select one folder.
  $(co_id).on('check_node.jstree', function (e, data) {
    checked = $(co_id).jstree("get_checked");
    var cur_checked = checked.join(','),
      folder_id = data.node.id;
    cur_checked = cur_checked
      .replace(',' + folder_id, '')
      .replace(folder_id, '');
    $(co_id).jstree('uncheck_node', cur_checked);
    addCertOrderJstree(folder_id);
  });
});
