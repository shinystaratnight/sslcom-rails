Feature: Create and Active a Reseller Account
  In order to sign up as a reseller
  An unregistered user
  Should be able to signup and activate a reseller account

  Background:
    Given no emails have been sent
      And I am not logged in

  @no-txn @reseller_invalid_signup
  Scenario Outline: I attempt to sign up as a reseller using invalid values
     When I sign up as a reseller using login "<login>" and email "<email>"
     Then I should be directed to path "<path>"
      And I should see "<message>"
  Examples:
    |login       |email       |path    |message                                |
    |            |            |/account|Login is too short                     |
    |user\ space |            |/account|Login should use only letters          |
    |            |email\ space|/account|Login is too short                     |
    |new_user    |            |/account|Email is too short                     |
    |new_user    |123456      |/account|Email should look like an email address|
    |user\ space |a@ssl.com   |/account|Login should use only letters          |

  @no-txn @valid_signup_w_email_sent
  Scenario: I should receive an email upon signup
    When I sign up as a reseller using login "new_user" and email "user@yahoo.com"
    Then "user@yahoo.com" should receive an email
    And "user@yahoo.com" should have 1 email

    #opening email
    When I open the email
    Then I should see "SSL.com Activation Instructions" in the email subject
    And I should see "Thank you for creating an account!" in the email body

    #following activation link
    When I click the first link in the email
    Then I should see "activate your account"
    And "foo@bar.com" should have no emails

    #setting password without confirmation password
    When I set the password to "password" but not the confirmation password
    Then I should see "match confirmation"

    #setting password
    When I set the password to "password" for the account
    Then I should be directed to path "/account/reseller/new"
      And I should see "your account has been activated"
      And "user new_user" should be an activated reseller
      And "user@yahoo.com" should receive 2 emails

    When I open the email with subject "Activation Complete"
    Then I should see "Your account has been activated" in the email body

  @password_reset @no-txn
  Scenario Outline: I forgot my password and should be able to reset it
    When I reset the password for username "<login>"
    Then I should see "Instructions to reset your password have been emailed to you."
    Then "<email>" should receive an email
    And "<email>" should have 1 email

    #opening email
    When I open the email
    Then I should see "SSL.com Password Reset Instructions" in the email subject
    And I should see "A request to reset your SSL account password has been made" in the email body
      And I should see "SSL Support Team" in the email body

    #following reset password link
    When I click the first link in the email
    Then I should see "Reset SSL.com Account Password"
    And "foo@bar.com" should have no emails

    #setting password without confirmation password
    When I set the password to "<password>" but not the confirmation password
    Then I should see "match confirmation"

    #setting password
    When I set the password to "<password>" for the account
    Then I should be directed to route path "account_path"
      And I should see the notice 'password successfully updated'

    #logout and verify password change
    When I log out
      And I go to route path 'login_path'
      And I log in with username '<login>' and password '<password>'
    Then I should be directed to route path "account_path"
      And I should see the notice 'successfully logged in'
  Examples:
    |login      |password    |email      |
    |leo@ssl.com|new_password|leo@ssl.com|

  @username_reminder @no-txn
  Scenario Outline: I forgot my username and should be able to retrieve it
    Given an activated user with login "<login>", password "<password>", and email "<email>" exists
    When I request a username reminder for email "<email>"
    Then I should see the notice 'Your username has been emailed to you'
    Then "<email>" should receive an email
    And "<email>" should have 1 email

    #opening email
    When I open the email
    Then I should see "SSL.com Username Reminder" in the email subject
    And I should see "A request to send your SSL username was made" in the email body
      And I should see "<login>" in the email body
      And I should see "SSL Support Team" in the email body
  Examples:
    |login     |password|email         |
    |some_user |password|user@email.com|
