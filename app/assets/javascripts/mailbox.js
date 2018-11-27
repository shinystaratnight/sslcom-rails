$(function($) {  
  $('.mail-item .mail-sender, .mail-item .mail-subject, .mail-item .mail-date')
    .on('click', function() {
      location.href = $(this).parent().data('read');
  });

  $('#all_mail_selected').on('click', function() {
    $('.mail-selected').prop("checked", $(this).is(':checked'));
  });

  $('.btn-reply-send').on('click', function(e) {
    e.preventDefault();
    $('#' + $(this).data('form-id')).submit();
  });

  $('.btn-mail-reply').on('click', function(e) {
    e.preventDefault();
    $('#' + $(this).data('form-id')).submit();
  });

  $('.btn-reply-cancel').on('click', function(e) {
    e.preventDefault();
    $('#' + $(this).data('form-container-id')).hide();
  });

  $('.btn-mail-reply').on('click', function(e) {
    e.preventDefault();
    $('#' + $(this).data('form-container-id')).show();
  });
});
