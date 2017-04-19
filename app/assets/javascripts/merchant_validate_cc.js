$(function($) {
  // Stripe Merhcant
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  stripeResponseHandler = function (status, response) {
      var form = $('.edit_funded_account, .new_order, .new_funded_account');
      if (response.error) {
        form.find('.cc-error').remove();
        showError(response.error.message);
        form.find('input[type=submit]').prop('disabled', true);
      } else {
        form.append($("<input type='hidden' name='billing_profile[stripe_card_token]' />").val(response.id));
        submitForm(form);
      }
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
  
  // Authorize.net Merhcant
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  function sendPaymentDataToAnet(form) {
    var secureData = {};
    secureData.cardData = {
      cardNumber: $('#billing_profile_card_number').val(),
      month:      $('#billing_profile_expiration_month').val(),
      year:       $('#billing_profile_expiration_year').val(),
      cardCode:   $('#billing_profile_security_code').val()
    };
    secureData.authData = {
      clientKey:  $('#credit_card_details').data('client-key'),
      apiLoginID: $('#credit_card_details').data('api-login-id')
    };
    // Pass the card number and expiration date to Accept.js for submission to Authorize.Net.
    Accept.dispatchData(secureData, responseHandler);

    function responseHandler(response) {
      if (response.messages.resultCode === "Error") {
        form.find('.cc-error').remove();
        response.messages.message.forEach(function(err) {
          showError(err.text.replace('CVV', 'Security Code'));
        });
        form.find('input[type=submit]').prop('disabled', true);
      } else {
        submitForm(form);
      }
    }
  }
  
  function submitForm(form){
    form.find('.cc-error').remove();
    form.get(0).submit();
    clearCardInfo();
  }
  
  function clearCardInfo() {
    $('#billing_profile_card_number').val('');
    $('#billing_profile_security_code').val('');
  }
  
  function showError(message) {
    $('#credit_card_details .subheading')
      .before('<div class="cc-error">' + message + '</div>');
  }
  
  $('.edit_funded_account, .new_order, .new_funded_account').submit(function() {
    if ($('#billing_profile_card_number').attr('required')=='required') {
      var form    = $(this),
          gateway = $('#credit_card_details').data('gateway');
      // Disable the submit button to prevent repeated clicks
      form.find('input[type=submit]').prop('disabled', true);
      gateway=='stripe' ? createStripeToken() : sendPaymentDataToAnet(form);
      return false;
    }
  });
  
  $('#payment_method_paypal, #payment_method_credit_card').on('click ', function() {
    if ($(this).is(':checked')) {
      $.profileRequiredToggle(
        $(this).attr('id') == 'payment_method_paypal' ? 'disable' : 'enable'
      );
    }
  });
});
