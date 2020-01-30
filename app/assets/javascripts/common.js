//= require jquery_ujs
//= require jquery-ui
//= require application
//= require jquery.livequery
//= require multifile/jquery.MetaData
//= require multifile/jquery.MultiFile.pack
//= require multifile/jquery.blockUI
//= require jquery.cookie
//= require jquery.json-2.2.min
//= require jCal
//= require datejs
//= require merchant_validate_cc
//= require popper
//= require bootstrap-sprockets
//= require invoice_section
//= require vakata-jstree/jstree
//= require deitch-jstree-grid/jstreegrid
//= require folders
//= require mailbox
//= require certificate_enrollment

$(document).ready(function(){
  $('input#file').change(function(){
    var fd = new FormData();
    var id = $('#user_id').val();
    var files = $('#file')[0].files[0];
    fd.append('file', files);
    fd.append('user_id', id);

    // AJAX request
    $.ajax({
      url: '/users/upload_avatar',
      type: 'post',
      data: fd,
      contentType: false,
      processData: false,
      statusCode: {
        200: function(response){
          $('#preview').append("<img src='" + response.responseText + "' width='300' height='300' style='display: inline-block;'>");
        },
        422: function(response){
          alert(response.responseText);
        }
      },
    });
  });
});
