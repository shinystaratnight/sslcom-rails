# @firewatir
Feature: Manage SSL Account
  In order to keep the customer's information up to date
  An appropriately authorized user
  Should be able to change account information

  Background:
    Given no emails have been sent
      And I am not logged in

  @permissions_on_ssl_account @no-txn
  Scenario Outline: User should only be able to access his/her account. Admins can access everyone's account
    Given "user <user>"'s role "is" "<role>"
      And the user with username "<user>" and password "<pass>" is logged in

    #access his own settings page
    When he clicks the "Settings" "link"
    Then he should be directed to path "ssl_account("
      And he "<permission>" authorized to "<action>" the "<obj_id>" "<obj_type>" object

    #attempt to access someone else's settings page
    When he clicks the "Settings" "link"
    Then he should be directed to path "<cert_order_ref>"
      And he "<permission>" authorized to "<action>" the "<obj_id>" "<obj_type>" object
  Examples:
    |user       |pass  |cert_order_ref |role    |obj_id                |obj_type|permission |action          |
    |leo@ssl.com|123456|qwerty-dfaffs  |vetter  |new_signed_certificate|form    |is         |have on the page|
    |leo@ssl.com|123456|qwerty-dfaffs  |sysadmin|new_signed_certificate|form    |is         |have on the page|
    |leo@ssl.com|123456|qwerty-dfaffs  |reseller|new_signed_certificate|form    |is not     |have on the page|

  @change_password @no-txn
  Scenario Outline: I want to be able to change my password
    Given the user with username "<login>" and password "<password>" is logged in
    When I click the "Account" "link"
    Then I should see "Edit Account"

    When I click the "change password" "link"
    Then I should see "Edit Login Account Password"

    #left out the old password
    When I set the password to "<new_password>" for the account
    Then I should see the error 'Old password value does not match password to be changed'

    #provided old password but used invalid new password
    When I fill the "old_password" "text_field" with "<password>"
      And I set the password to "bad" for the account
    Then I should see the error 'too short'

    #setting password without confirmation password
    When I fill the "old_password" "text_field" with "<password>"
    When I set the password to "<password>" but not the confirmation password
    Then I should see "match confirmation"

    #do everything right
    When I fill the "old_password" "text_field" with "<password>"
      And I set the password to "<new_password>" for the account
    Then I should be directed to route path "edit_account_path"
      And I should see the notice 'Account updated'
      And "<email>" should receive an email
      And "<email>" should have 1 email

    #opening email
    When I open the email
    Then I should see "SSL.com Account Password Changed" in the email subject
    And I should see "Your SSL account password has successfully been changed" in the email body
      And I should see "SSL Support Team" in the email body
  Examples:
    |login      |password|new_password|email      |
    |leo@ssl.com|123456  |new_password|leo@ssl.com|
