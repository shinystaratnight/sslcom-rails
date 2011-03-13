Feature: Manage SSL Certificates
  In order to manage ssl certificates
  An appropriately authorized user
  Should be able to view, procure, edit, and update ssl certificates

  @no-txn @anonymous_user_ordering_certificate_no_csr
  Scenario: Anonymous user buying ssl certificates with no csr
    Given I am not logged in
    And my cart is empty

    #add stuff to cart
    When I add an ssl certificate to the cart
      |product       |years|domains                   |price |
      |high_assurance|1    |                          |69.00 |
      |high_assurance|1    |                          |69.00 |
      |high_assurance|3    |                          |155.00|
      |evucc         |1    |www.c.com, asd.com, sd.com|747.00|
      |evucc         |1    |www.c.com, asd.com, sd.com|747.00|
      And I checkout
    Then I should be directed to route path "new_order_path"
      And the order amount displayed should be the same as the cart amount

    When I click the "radio" with "has_account_false" "id"
      And I enter my new user information
      |login|email  |password|confirm|
      |b001b|b@b.com|123456  |123456 |

      And I enter my profile information
      |first_name|last_name|address1|address2|city    |state|country           |postal_code|phone       |
      |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States     |77777      |123-123-1234|

      And I enter my credit card payment information
      |card_type|card_number     |exp_mo|exp_yr|security_code |result_code|
      |Visa     |4111111111111111|8     |2012  |1234          |01         |

      And I click the submit image button
    Then I should be directed to the order page
#      And I should see line items for this order
#      And "b@b.com" should receive an email
#      And "b@b.com" should have 1 email
#      And my cart should be empty
#
#    #opening email
#    When I open the email
#    Then I should see "SSL.com Confirmation for Order ##{Order.last.reference_number}" in the email subject
#      And I should see "The following SSL certificate order has been placed" in the email body
#
#
#    #proceed to buy the certificate
#    When he applies the order to the reseller account
#    Then he should be at step '3' of '4'
#      And he should see 'Applicant Information'
#
#    #getting distracted but the order can resume when convenient
#    When he clicks the "Orders" "link"
#      And he clicks the link to the current certificate order in progress
#    Then he "is not" authorized to "have on the page" the "new_signed_certificate" "form" object
#
#    #continue on
#    When he clicks the action link for the currently displayed order
#    Then he should be at step '3' of '4'
#      And he should see 'Applicant Information'
#
#    #ooops, we forgot to indicate we validated the customer
#    When he clicks the next button and 'OK' on the popup confirmation
#    Then he should see a popup containing "Please click the validated checkbox to proceed with order placement."
#
#    #ooops, we forgot to enter the required fields
#    When he clicks the "checkbox" with "validation" "id"
#      And he clicks the next button
#    Then he should see an error explanation
#      And he should see "be blank"
#
#    When he fills in the applicant information using
#      |department|po_box|address1|postal_code|
#      |Gaming    |123   |123 Rd  |77777      |
#      And he clicks the next button
#    Then he should be at step '4' of '4'
#      And "sales@ssl.com" should have 1 email
#      And he should see certificate order receipt recipients
#      And he should see certificate order confirmation recipients
#      And he should see processed certificates recipients
#
#    When he clicks the "click here." "link"
#    Then he should be directed to the new certificate order path
#      And he "<permission>" authorized to "<action>" the "<obj_id>" "<obj_type>" object
#  Examples:
#    |user       |pass  |cert_order_ref |role    |obj_id                         |obj_type  |permission|action          |
#    |leo@ssl.com|123456|qwerty-dfaffs  |reseller|csr_signed_certificate_by_text |text_field|is not    |have on the page|
#    #|leo@ssl.com|123456|qwerty-dfaffs  |vetter  |csr_signed_certificate_by_text |text_field|is        |have on the page|
#    #|leo@ssl.com|123456|qwerty-dfaffs  |sysadmin|csr_signed_certificate_by_text |text_field|is        |have on the page|

  @submit_signed_certificate @no-txn @setup_certificates
  Scenario: Submitting a signed certificate on certificate order page
    Given there is an open certificate order with ref number 'qwerty-dfaffs'
      And the admin user with username 'sy_adm1n_' and password 'kool1o' is logged in
      And he goes to the certificate order page for 'qwerty-dfaffs'

    #submit invalid signed certificate
    When he submits "some bogus value for a signed certificate" as the signed certificate
    Then he should see "" in the "signed_certificate_body" "textarea"

    #submit valid signed certificate
    When he submits the variable "@lobby_sb_betsoftgaming_com_signed_cert" as the signed certificate
    Then the certificate content fields should be updated with "@lobby_sb_betsoftgaming_com_signed_cert" fields

    #resubmit the same signed certificate
    When he resubmits the variable "@lobby_sb_betsoftgaming_com_signed_cert" as the signed certificate
    Then the certificate content fields should remain the same as "@lobby_sb_betsoftgaming_com_signed_cert" fields

  @expiring_certificates @no-txn @setup_certificates
  Scenario Outline: An expiring or expired certificate should show colored indicators
    Given the user with username "leo@ssl.com" and password "123456" with role "reseller" is logged in
      And "user leo@ssl.com"'s expiration trigger is set to "<num_of_days_before_trigger>" "<trigger_order>"
      And there is a processed certificate order with ref number 'qwerty-dfaffs'
    When certificate order 'qwerty-dfaffs' is expiring in "<days_until_expiration>"
      And he goes to the certificate order page for 'qwerty-dfaffs'
    Then there should "<expiring?>" be an expiring indicator
      And there should "<expired?>" be an expired indicator
  Examples:
    |num_of_days_before_trigger|trigger_order|days_until_expiration|expiring?|expired?|
    |30                        |1            |45                   |not      |not     |
    |30                        |1            |15                   |         |not     |
    |30                        |1            |-15                  |not      |        |

  @status_messages @no-txn @setup_certificates
  Scenario Outline: Status messages need to reflect the stage the certificate order is in
    Given the user with username "leo@ssl.com" and password "123456" with role "reseller" is logged in
      And there is a processed certificate order with ref number 'qwerty-dfaffs'
    When certificate order 'qwerty-dfaffs' is at stage "<stage>"
      And he goes to the certificate order page for 'qwerty-dfaffs'
    Then he should see "<status>"
  Examples:
    |num_of_days_before_trigger|trigger_order|days_until_expiration|expiring?|expired?|
    |30                        |1            |45                   |not      |not     |
    |30                        |1            |15                   |         |not     |
    |30                        |1            |-15                  |not      |        |

  Scenario: Anonymous user adds items
    Given I am not logged in
      And there is an empty shopping cart
      And I add some items to the cart
    When I click the 'link' with 'cart_size' 'id'
    Then I should be at path '/orders/show_cart/current'
      And I should see 'Total'
      And I should see '$21.97 USD' in 'cart_total'

  Scenario: Anonymous user adds items then clicks 'remove all items' button
    Given I am not logged in
      And there is an empty shopping cart
      And I add some items to the cart
    When I click the 'link' with 'cart_size' 'id'
      And I click the 'button' with 'empty_cart' 'id'
    Then I should be at path '/orders/show_cart/current'
      And I should see 'Total'
      And I should see '$0.00 USD' in 'cart_total'

  Scenario: Anonymous user adds items then removes individual items
    Given I am not logged in
      And there is an empty shopping cart
      And I add some items to the cart
    When I click the 'link' with 'cart_size' 'id'
      And I click the 'link' with 'release_45' 'id'
    Then I should be at path '/orders/show_cart/current'
      And I should see '$14.98 USD' in 'cart_total'
      And I should see '2' in 'cart_size'

  Scenario: Anonymous user check out
    Given I am not logged in
      And there is an empty shopping cart
    When I add some items to the cart
      And I click the 'link' with 'cart_size' 'id'
      And I click the 'link' with 'Checkout' 'text'
      And I should be directed to the login path
      And I should see '» Click here to sign up' in the 'link' with attribute 'href' == '/signup'
      And I am prompted with "have an account?"
      And I am prompted with "Log in"
      And I log in with username 'aaron' and password 'test'
      And I should be at path 'secure/allocate_funds_for_order'
      And I click the 'link' with 'Click here to add a new credit card'
      And I enter my profile information
      |first_name|last_name|address1|address2|city    |state|country           |postal_code|phone       |
      |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States     |77777      |123-123-1234|

      And I enter my credit card payment information
      |card_type|card_number  |exp_mo|exp_yr|security_code|result_code|
      |Visa     |4222222222222|8    |2010  |000          |01         |

      And I click the submit button

      Then I should see "(TEST) The transaction was successful"
        And I should see "Order Number: xxxxxxx"
        And I should see "xxxx-xxxx-xxxx-2222"
        And I should see a "click here to view/download clips" "link"

  Scenario Outline: Registered user loads cart then deposits funds to prove order does not "bleed over" into the deposit
    Given the user with username "<user>" and password "<pass>" is logged in
      And there is an empty shopping cart
    When he adds some items to the cart
      And "<user>" makes a deposit
        |first_name|last_name|address1|address2|city    |state|country      |postal_code|phone       |card_type|card_number     |exp_mo|exp_yr|security_code|amount|result_code|
        |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States|77777      |123-123-1234|Visa     |5588280019102398|8     |2010  |000          |$25.00|01         |
    Then he should see "Amount: $25.00 USD"
      And he should not see "Order Details"

  Examples:
    |user |pass|
    |aaron|test|

  #unfinished

  Scenario: Anonymous user check out
      Given I am not logged in
        And there is an empty shopping cart
      When I add some items to the cart
        And I click the 'link' with 'Checkout' 'text'
      Then I should be at path '/orders/show_cart/current'
        And I should see '$14.98 USD' in 'cart_total'
        And I should see '2' in 'cart_size'



  Scenario: Anonymous user check out
      Given I am not logged in
      When I add the "first" video clip to my cart
          And I click the "my cart" "link"
          And I click the "check out" "link"
          And I am prompted to "register"
          But I am also prompted to "login"
          And I register
          And I log in
          And I am redirected to the payment page
          And I enter my profile information
          |first_name|last_name|address1|address2|city    |state|country           |postal_code|phone       |
          |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States     |77777      |123-123-1234|

          And I enter my credit card payment information
          |card_type|card_number  |exp_mo|exp_yr|security_code|result_code|
          |Visa     |4222222222222|8    |2010  |000          |01         |

          And I click the submit button

          Then the payment gateway should return result
          |code|
          |01  |

            And I should see "(TEST) The transaction was successful"
            And I should see "Order Number: xxxxxxx"
            And I should see "xxxx-xxxx-xxxx-2222"
            And I should see a "click here to view/download clips" "link"

  Scenario: Registered user checks out
      Given the user with username "nutty" and password "jama1kama1" is logged in
      When he visits the payment page
        And he enters his profile information
        |first_name|last_name|address1|address2|city    |state|country           |postal_code|phone       |
        |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States     |77777      |123-123-1234|

        And he enters his credit card payment information
        |card_type|card_number  |exp_mo|exp_yr|security_code|result_code|
        |Visa     |4222222222222|8    |2010  |000          |01         |

        And he clicks the submit button

      Then he should see result
      |code|
      |01  |


Scenario: Only admins should be able to process certs
Given I'm logged in as <role>
When I go to a certificate order page that is <status>
Then I <should_or_not> see a signed certificate submit area

Scenario: Only customers can manage their own certificate orders

Scenario: Only admins and vetting_admins can log in as any user

Scenario: Only resellers will get reseller pricing screens (ie deposit and pricing tiers)

Scenario: Customers and resellers can buy certs via cart and they will appear as credits that show up on orders page

Scenario: Only admins can override validation processes

Scenario: Resellers as registered agents have express certificate procurement flow for non EV certs

Scenario: EV certs require 6 step process flow

Scenario: SSL Site Report Artifacts will display artifacts that are both approved by admins and customers

Scenario: On order completion, a ready notice email will be sent to all contacts and a certificate attached email will be sent to designated contact

Scenario: Only registered users can access account settings page

Scenario: Only resellers can access reseller settings page



Various admin screens

change number or certs pourchased to unprocessed certificates


