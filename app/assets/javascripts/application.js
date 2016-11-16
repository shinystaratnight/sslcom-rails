// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function remove_fields(link) {
   $(link).prev("input[type=hidden]").val("1");
   $(link).closest(".fields").hide();
}

function add_fields(link, association, content) {
   var new_id = new Date().getTime();
   var regexp = new RegExp("new_" + association, "g");
   $(link).parent().before(content.replace(regexp, new_id));
}

function refreshRolesSelect(account_id) {
  var roles_list = JSON.parse($.toJSON($('#user_account_roles')
    .data('accounts-roles')))[account_id];
  if (roles_list) {
    $('#user_role_ids option:selected').removeAttr('selected');
    roles_list.forEach(function(role_id) {
      $('#user_role_ids option[value="' + role_id + '"]')
        .attr('selected', 'selected');
    });
    $("#user_role_ids").select2();
  }
}

$.ajaxSettings.dataType = "json";

jQuery(function($) {
  var flash_notice = $('.flash_message.notice span');
  $('#user_ssl_account_id').on('change', function() {
    refreshRolesSelect($(this).val());
  });
  if (flash_notice.length && flash_notice.text().includes('been added to account')) {
    $('.simple-tooltip-cont, .simple-tooltip').removeClass('hidden');
  }
});
