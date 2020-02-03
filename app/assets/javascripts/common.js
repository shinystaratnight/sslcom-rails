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
    $('button#spinner').show();
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
        200: function(){
          $.get('/users/avatar').done(function(response){
            $('button#spinner').hide();
            $('.preview').hide();
            $('#preview').append("<img class='preview' src='" + response.data.links.large_avatar_url + "' width='300' height='300' style='display: inline-block;'>");
          })
        },
        422: function(response){
          $('button#spinner').hide();
          $('#toast').append('<span class="badge badge-danger">There was an error uploading your image. Please try again later.</span>');
          $('#toast').toast();
          // alert(response.responseText);
        }
      },
    });
  });
});
