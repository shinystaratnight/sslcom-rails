$(function($) {
  stripeResponseHandler = function (status, response) {
      var $form = $('.edit_funded_account, .new_order');
      if (response.error) {
        $form.find('.cc-error').remove();
        showError(response.error.message);
        $form.find('input[type=submit]').prop('disabled', true);
      } else {
        $form.find('.cc-error').remove();
        $form.append($("<input type='hidden' name='billing_profile[stripe_card_token]' />").val(response.id));
        $form.get(0).submit();
        clearCardInfo();
      }
      return false;
  };

  showError = function (message) {
    $('#credit_card_details .subheading')
      .before('<div class="cc-error">' + message + '</div>');
    return false;
  };
    
  createStripeToken = function(message) {
    Stripe.card.createToken({
      number:        $('#billing_profile_card_number').val(),
      cvc:           $('#billing_profile_security_code').val(),
      exp_year:      $('#billing_profile_expiration_year').val(),
      exp_month:     $('#billing_profile_expiration_month').val(),
      address_line1: $('#billing_profile_address_1').val(),
      address_city:  $('#billing_profile_city').val(),
      address_state: $('#billing_profile_state').val(),
      address_zip:   $('#billing_profile_postal_code').val(),
      name:          $('#billing_profile_first_name').val()+' '+$('#billing_profile_last_name').val()
    }, stripeResponseHandler);
  };
  
  clearCardInfo = function() {
    $('#billing_profile_card_number').val('');
    $('#billing_profile_security_code').val('')
  };
   
  $('.edit_funded_account, .new_order').submit( function() {
    if ($('#billing_profile_card_number').attr('required')=='required') {
      var $form = $(this);
      // Disable the submit button to prevent repeated clicks
      $form.find('button').prop('disabled', true);
      createStripeToken();
      return false;
    }
  });
});
