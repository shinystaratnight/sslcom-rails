$(function($) {
  
  $('#invoice-container-ext').hide();
  
  function hideAllForms() {
    $('#frm-inv-download').hide();
    $('#frm-inv-download').hide();
    $('#invoice-container-ext').hide();
  }

  $('#invoice-container-ext').on('click', '#btn-inv-cancel, #btn-inv-update-cancel', function(e) {
    e.preventDefault();
    hideAllForms();
  });
  
  $('#btn-invoice-generate a').on('click', function(e) {
    e.preventDefault();
    $('#frm-inv-update').hide();
    $('#invoice-container-ext').show('slow');
    $('#frm-inv-download').show('slow');
  });
  
  $('#btn-invoice-update a').on('click', function(e) {
    e.preventDefault();
    $('#frm-inv-download').hide();
    $('#invoice-container-ext').show('slow');    
    $('#frm-inv-update').show('slow');
  });
  
  $('#frm-inv-update').on('ajax:success', function(xhr, data, status) {
    $('.errors-invoice-update').remove();
    hideAllForms();
  });
    
  $('#frm-inv-update').on('ajax:error', function(xhr, data, status) {
    $('.errors-invoice-update').remove();
    var errors = JSON.parse(data.responseText);
    for (var key in errors) {
      if (errors.hasOwnProperty(key)) {
        $('#invoice-container-errors').prepend(
          "<div class='errors-invoice-update'>"
          + key.replace('_', ' ') + ": " + errors[key] + "</div>"
        );
        $('#invoice-container-errors').focus();
      }
    }
  });
  
  // Sysadmin Section in Monthly Invoice
  $('#invoice-container-admin').hide();
  
  $('#frm-mo-inv-update').on('ajax:success', function(xhr, data, status) {
    $('.errors-invoice-update').remove();
    $('#invoice-container-admin').hide();
  });
  
  $('#invoice-container-admin').on('click', '#btn-inv-update-cancel', function(e) {
    e.preventDefault();
    $('#invoice-container-admin').hide();
  });
  
  $('#lnk-mo-invoice-update').on('click', function(e) {
    console.log('lnk-mo-invoice-update');
    e.preventDefault();
    $('#invoice-container-admin').show('slow');
  });
  
  $('#frm-mo-inv-update').on('ajax:error', function(xhr, data, status) {
    $('.errors-invoice-update').remove();
    var errors = JSON.parse(data.responseText);
    for (var key in errors) {
      if (errors.hasOwnProperty(key)) {
        $('#invoice-admin-errors').prepend(
          "<div class='errors-invoice-update'>"
          + key.replace('_', ' ') + ": " + errors[key] + "</div>"
        );
        $('#invoice-admin-errors').focus();
      }
    }
  });
});
