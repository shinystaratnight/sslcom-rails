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

function copyToClipboard(text, el) {
  var copyTest = document.queryCommandSupported('copy');
  var elOriginalText = el.attr('data-original-title');

  if (copyTest === true) {
    var copyTextArea = document.createElement("textarea");
    copyTextArea.value = text;
    document.body.appendChild(copyTextArea);
    copyTextArea.select();
    try {
      var successful = document.execCommand('copy');
      var msg = successful ? 'Copied!' : 'Whoops, not copied!';
      el.attr('data-original-title', msg).tooltip('show');
    } catch (err) {
      console.log('Oops, unable to copy');
    }
    document.body.removeChild(copyTextArea);
    el.attr('data-original-title', elOriginalText);
  } else {
    // Fallback if browser doesn't support .execCommand('copy')
    window.prompt("Copy to clipboard: Ctrl+C or Command+C, Enter", text);
  }
}

$(document).ready(function(){
  $('input#file').change(function(){
    $('button#spinner').show();
    var fd = new FormData();
    var id = $('#user_id').val();
    var files = $('#file')[0].files[0];
    fd.append('file', files);
    fd.append('user_id', id);
    $('.alert').remove();
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
            $('.preview').remove();
            $('#preview').append("<img class='preview' src='" + response.large_avatar_url + "' width='300' height='300' style='display: inline-block;'>");
          });
        },
        422: function(response){
          $('button#spinner').hide();
          $('.preview').remove();
          if(response.responseText.match(/bucket|denied/i)){
            $('#alert').append('<div class="alert alert-danger" role="alert">There was an error uploading your image. Please try again later.<button type="button" class="close" data-dismiss="alert" aria-label="Close"> <span aria-hidden="true">&times;</span> </button></div>');
          }
          else if(response.responseText.match(/content/i)){
            $('#alert').append('<div class="alert alert-danger" role="alert">This file is not acceptable. Please choose a PNG, JPEG, or GIF file.<button type="button" class="close" data-dismiss="alert" aria-label="Close"> <span aria-hidden="true">&times;</span> </button></div>');
          }
          else{
            $('#alert').append('<div class="alert alert-danger" role="alert">' + response.responseText + '<button type="button" class="close" data-dismiss="alert" aria-label="Close"> <span aria-hidden="true">&times;</span> </button></div>');
          }
        }
      },
    });
  });

  $('.js-tooltip').tooltip();

  $('.js-copy').click(function() {
    var text = $(this).attr('data-copy');
    var el = $(this);
    copyToClipboard(text, el);
  });
});
