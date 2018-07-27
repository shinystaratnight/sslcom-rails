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
      var v = $('#folder-scan').val();
      $('#folders-tree').jstree(true).search(v);
    }, 250);
  });
});
