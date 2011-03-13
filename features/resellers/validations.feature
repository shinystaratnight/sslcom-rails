Feature: Validations for SSL Certificates
  In order to properly complete SSL Certificate orders
  Validations need to be performed
  So that certificates are issued to authorized parties

  Background:
    Given no emails have been sent
      And the user with username "leo@ssl.com" and password "123456" is logged in
      And I click the "Validations" "link"

@validation_screen @no-txn
  Scenario Outline: I want to see what validation requirements are outstanding for a certificate order based on the validation rules
    #fill some invalid values
    When I fill the "reminder_notice_triggers_" "text_field" indexed "1" with "700"
      And I click the submit image button
    Then I should see error "Reminder notice trigger 1 must be in the range"
      And I should see "700" in the "reminder_notice_triggers_" "input"
      And there should be an error field indicator

    When I fill the "reminder_notice_triggers_" "text_field" indexed "3" with "abc"
      And I click the submit image button
    Then I should see error "Reminder notice trigger 1 must be in the range"
      And I should see error "Reminder notice trigger 3 must be an integer"
      And I should see "abc" in the "reminder_notice_triggers_" "input"
      And there should be "2" error field indicators

    #leave all values blank
    When I fill all the "reminder_notice_triggers_" "input"s with ""
      And I click the submit image button
    Then I should see the notice "Account settings were successfully updated"

    #fill in all values
    When I click the "Settings" "link"
      And I fill the "reminder_notice_triggers_" "text_field" indexed "1" with "-30"
      And I fill the "reminder_notice_triggers_" "text_field" indexed "2" with "60"
      And I fill the "reminder_notice_triggers_" "text_field" indexed "3" with "15"
      And I fill the "reminder_notice_triggers_" "text_field" indexed "4" with "30"
      And I fill the "reminder_notice_triggers_" "text_field" indexed "5" with "0"
      And I click the submit image button
    Then I should see the notice "Account settings were successfully updated"

    #verify settings were saved
    When I click the "Settings" "link"
    Then I should see "60" in the "reminder_notice_triggers_" "input"
    Then I should see "30" in the "reminder_notice_triggers_" "input"
    Then I should see "15" in the "reminder_notice_triggers_" "input"
    Then I should see "-30" in the "reminder_notice_triggers_" "input"
    Then I should see "0" in the "reminder_notice_triggers_" "input"

@upload_validation_docs @no-txn
  Scenario Outline: I want to be able to upload required validation documents
    #select certificate admin and tech contact
    When I go the provide validation docs screen for a specific order
    Then I should see which validations are required to complete the order
      And I should see which document types I should upload to satisfy these validation requirements

    #verify the settings stuck
    When I click the "Settings" "link"
    Then I should see the checkbox with "preferred_<cert_role1_chkbox>" "id" checked
      And I should see the checkbox with "preferred_<cert_role2_chkbox>" "id" checked

    #deselect one item
    When I uncheck the checkbox with "preferred_<cert_role1_chkbox>" "id"
      And I click the submit image button
    Then I should see the notice "Account settings were successfully updated"

    #verify the settings stuck
    When I click the "Settings" "link"
    Then I should see the checkbox with "preferred_<cert_role1_chkbox>" "id" unchecked

    #select recipients but leave the text field blank
    When I check the checkbox with "preferred_<recipients_chkbox>" "id"
      And I fill the "<email_text_field>" "text_field" with ""
      And I click the submit image button
    Then I should see the error 'cannot be blank'
      #for the checkbox (not shown), messagebox and for the text box
      And there should be "3" error field indicators

    #select recipients and fill the text field with invalid email addys
    When I fill the "<email_text_field>" "text_field" with "abc"
      And I click the submit image button
    Then I should see the error "has invalid email addresses"
      And there should be "3" error field indicators

    #select recipients and fill the text field with valid email addys
    When I fill the "<email_text_field>" "text_field" with "test@test.com another@yahoo.com"
      And I click the submit image button
    Then I should see the notice "Account settings were successfully updated"

    #verify the addys stuck
    When I click the "Settings" "link"
    Then I should see "test@test.com another@yahoo.com" in the "<email_text_field>" "text_field"

  Examples:
    |cert_role1_chkbox              |cert_role2_chkbox             |recipients_chkbox               |email_text_field|
    |reminder_include_cert_admin    |reminder_include_cert_tech    |reminder_notice_destinations    |reminder_email  |
    |confirmation_include_cert_admin|confirmation_include_cert_bill|confirmation_recipients         |confirmation_email|
    |receipt_include_cert_admin     |receipt_include_cert_bill     |receipt_recipients              |receipt_email   |
    |processed_include_cert_admin   |processed_include_cert_tech   |processed_certificate_recipients|processed_email |

@validation_requirements_for_certificate @no_txn
  Scenario Outline: I want to be able to specify flexible validation requirements for a certificate order
    #select certificate admin and tech contact
    When I go the set validation requirements for a certificate type
    Then I should have the option to add a requirement type
      And I should have the option to add an AND or OR rule to the requirement

    When I go the set validation requirements for a certificate type
    Then I should have the option to add a requirement group
      And I should have the option to any number of requirement types to this group
      And I should have the option to add an AND or OR rule to each requirement in the group
