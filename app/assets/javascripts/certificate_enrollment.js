$(function($) {
  var $approval_form = $("#frm-admin-approve-request");

  function validateFormData() {
    
  }

  function submitEnrollmentForm(add_data) {
    var data = $approval_form.serialize();
    var url = add_data.apiUrl ? add_data.apiUrl : $approval_form.prop("action");

    data = data
      .concat("&domains=", add_data.domains)
      .concat("&duration=", add_data.duration)
      .concat("&certificate_id=", add_data.certificateId)
      .concat("&request_id=", add_data.requestId);
    
    $.ajax({
      url: url,
      data: data,
      dataType: "JSON",
      type: "POST",
      success: function (data) {
        if (data.is_ordered) {
          location.reload();
        } else {
          alert("Something went wrong due to errors. " + JSON.stringify(data));
        }
      }
    });
  }

  function objectifyForm(formArray) {
    var returnArray = {};
    for (var i = 0; i < formArray.length; i++){
      name = formArray[i]["name"]
        .replace("certificate_order[certificate_contents_attributes][0][", "")
        .replace("]", "");
      returnArray[name] = formArray[i]["value"];
    }
    return returnArray;
  }
  
  $("#btn-brandable-enroll").on("click", (function(e) {
    e.preventDefault();

    data = objectifyForm($("#new_certificate_order").serializeArray());
    cer = "certificate_enrollment_request";
    enrollForm = $("#frm-sslcom-cert-enroll");
    enrollForm.find("#" + cer + "_common_name").val(data.common_name);
    enrollForm.find("#" + cer + "_signing_request").val(data.signing_request);
    enrollForm.find("#" + cer + "_server_software_id").val(data.server_software_id);
    enrollForm.find("#" + cer + "_additional_domains").val(data.additional_domains);
    enrollForm.submit();
  }));

  $(".btn-admin-cert-enroll-approve").on("click", (function(e) {
    e.preventDefault();
    var r = confirm("Are you sure you want to APPROVE this request?");
    if (r == true) {
      submitEnrollmentForm( $(this).data() );
    }
  }));
});
