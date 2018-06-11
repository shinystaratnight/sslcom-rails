$(function($) {
  
  $('#invoice-container-ext').hide();
  
  function hideAllForms() {
    var ids = [
      '#frm-inv-download',
      '#invoice-container-ext',
      '#invoice-container-credit',
      '#invoice-container-admin'
    ];
    $(ids.join(', ')).hide();
  }

  $('#invoice-container-ext').on('click', '#btn-inv-cancel, #btn-inv-update-cancel', function(e) {
    e.preventDefault();
    hideAllForms();
  });
  
  $('.btn-edit-invoice-item').on('click', function(e) {
    e.preventDefault();
    $('#mi-update-item-desc-'+ $(this).data('order-ref')).show('slow');
  });
  
  $('.btn-cancel-invoice-item').on('click', function(e) {
    e.preventDefault();
    $('#mi-update-item-desc-'+ $(this).data('order-ref')).hide();
  });

  $('#invoice-container-credit').on('click', '#btn-inv-update-cancel', function(e) {
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
  $('#invoice-container-credit').hide();
  
  $('#frm-mo-inv-update').on('ajax:success', function(xhr, data, status) {
    $('.errors-invoice-update').remove();
    $('#invoice-container-admin').hide();
  });
  
  $('#invoice-container-admin').on('click', '#btn-inv-update-cancel', function(e) {
    e.preventDefault();
    $('#invoice-container-admin').hide();
  });
  
  $('#lnk-mo-invoice-update').on('click', function(e) {
    e.preventDefault();
    $('#invoice-container-admin').show('slow');
  });
  
  $('#invoice-container').on('click', '#lnk-mo-invoice-credit', function(e) {
    e.preventDefault();
    hideAllForms();
    $('#invoice-container-credit').show('slow');
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
  
  // Monthly/daily Invoice Manage Items
  var init_transfer_url = $('#btn-transfer-mi-items').attr('href');
  
  function updateTransferItemsUrl() {
    var orders = [],
      invoice = $('#mo-select').find(':selected').val();
    $('.chk-items-selected:checked').each(function() {
      orders.push(this.id);
    });
    $('#btn-transfer-mi-items').attr('href', 
      init_transfer_url + '?invoice=' + invoice + "&orders=" + orders
    );
  }
  
  $('.chk-items-selected').on('click', function() {
    var id = $(this).attr('id'),
      count = $('#items-selected strong').data('count'),
      amount = $('#items-selected-amt strong').data('amount');
      
    if ($(this).is(':checked')) {
      amount += $(this).data('amount');
      count  += 1;
      $(this).parents('tr').css('background-color', 'rgb(204, 255, 204)');
    } else {
      amount -= $(this).data('amount');
      count  -= 1;
      $(this).parents('tr').css('background-color', '#ffffff');
    }
    
    count == 0 ? $('#btn-transfer-mi-items').hide() : $('#btn-transfer-mi-items').show();
    $('#items-selected strong').text(count);
    $('#items-selected strong').data('count', count);
    $('#items-selected-amt strong').text('$' + amount.toFixed(2));
    $('#items-selected-amt strong').data('amount', amount);
    updateTransferItemsUrl();
  });
  
  $('#mo-select').on('change', function() {
    var selected = $(this).find(':selected').val(),
      btn_text = (selected == 'new_invoice') ? 'Create' : 'Transfer Items';
      
    selected = (selected == 'new_invoice') ? 'NEW' : selected;
    $('#items-invoice-type strong').text(selected);
    $('#btn-transfer-mi-items').text(btn_text);
    updateTransferItemsUrl();
  });
  
  $('#mi_all_items').on('click', function() {
    var amount = $('#items-selected-amt strong').data('total').toFixed(2),
      checked = $(this).is(':checked'),
      bc = checked ? 'rgb(204, 255, 204)' : '#ffffff',
      amount = checked ? amount : 0,
      count = checked ? $('#items-selected strong').data('total') : 0;
    
    $('.chk-items-selected').prop('checked', checked);
    $('.chk-items-selected').parents('tr').css('background-color', bc);
    $('#items-selected strong').text(count);
    $('#items-selected strong').data('count', count);
    $('#items-selected-amt strong').text('$' + amount);
    $('#items-selected-amt strong').data('amount', amount);
    count == 0 ? $('#btn-transfer-mi-items').hide() : $('#btn-transfer-mi-items').show();
    updateTransferItemsUrl();
  });  
});
