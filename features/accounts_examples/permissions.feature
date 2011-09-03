#use driver @rack_test for inline and @selenium for remote
#when changing drivers, be sure to change DatabaseCleaner.strategy in db_cleaner.rb
#also all comments must appear before tags with no comments in-between tags
#@rack_test
@firebug
@selenium @no-txn @remote
@setup_certificates

Feature: Permissions to pages
  As a user
  I want to be able to access certain pages while restricting others from accessing those pages
  So that my security is not compromised from unintended or illicit use

  @passed_selenium_remote @passed_rack_test
  Scenario: User can must sent validation requests from one of the selected email addresses
    Given an activated user Fred exists
      And Fred has a new dv certificate order at the validation prompt stage
      And I login as Fred
     When I request domain control validation be sent during checkout
     Then a domain control validation request should be sent

  #email testing doesn't work with selenium_remote
  @passed_rack_test
  Scenario: User can send validation requests for a new order to other users
    Given an activated user Fred exists
      And Fred has a new dv certificate order at the validation prompt stage
      And I login as Fred
#   would love to get the next line working - oh well
#      And I'm logged in as Fred
     When I request domain control validation from somebody@example.com
      And "somebody@example.com" opens the email
     Then "somebody@example.com" should have an email
      And they should see "Validation Request for SSL.com Certificate lobby.sb.betsoftgaming.com" in the email subject
      And they should see "Additional validation information is required" in the email body
      And they should see "lobby.sb.betsoftgaming.com" in the email body

  #email testing doesn't work with selenium_remote
  Scenario: User can send validation requests for a completed order to other users
    Given an activated user Fred exists
      And Fred has a completed but unvalidated dv certificate order
      And I login as Fred
     When I request domain control validation from somebody@example.com
      And "somebody@example.com" opens the email
     Then "somebody@example.com" should have an email
      And they should see "Validation Request for SSL.com Certificate lobby.sb.betsoftgaming.com" in the email subject
      And they should see "Additional validation information is required" in the email body
      And they should see "lobby.sb.betsoftgaming.com" in the email body

#      And somebody should have access to the validation submittal page
#      And somebodyelse should not have access to the validation submittal page

  Scenario: Person who received a validation request should be able to supply validation
    Given a registered user Fred exists
      And Fred has a certificate order
      And I'm logged in as Fred
     When I request domain control validation from somebody@example.com
     Then somebody should receive a request email
      And somebody should have access to the validation submittal page
      And somebody else should not have access to the validation submittal page

  Scenario: Person who received a validation request should be able to forward request
  Scenario: Person who did not receive a validation request should not be able to supply validation
  Scenario: Anonymous users should not be able to see any validation pages
  Scenario: User logins when other users exist
    Given an activated user Fred exists
      And an activated user Bill exists
     When I login as Fred
     Then I should be logged in as Fred
      And I should not be logged in as Bill
      And I should have my user id in my session store

  Scenario: Logged-in user who fails logs in should be logged out
    Given an activated user Fred exists
     When I login as Fred
     Then I should be logged in as Fred
     When I login as someone else and fail
     Then I should not be logged in
      And I should see an error
      And I should not have an auth_token cookie
      And I should not have a user id in my session store

  Scenario: Logged out user can log out.
    Given I am logged out
     When I logout
     Then I should not be logged in
      And I should not have an auth_token cookie
      And I should not have a user id in my session store

  Scenario Outline: Log-in with bogus info should fail until it doesn't
  # TODO These stories rely on a user called 'fred' with a password 'fredpass'.
  # It might be a good idea to remove this coupling

    Given an activated user Fred exists
     When I login as Fred with password
     Then my login status should be out

    Examples:
      | user | login | pass | status |
      | Fred | Fred | haxor3 | out |
      | bill | bill | haxor3 | out |
      | Fred | Fred | peeppass | out |
      | Fred | Fred | Fredpass | in |

  Scenario: Logged in user can log out.
    Given an activated user Fred exists
     When I login as Fred
     Then I should be logged in as Fred
     When I logout
     Then I should see a confirmation
      And I should not be logged in
      And I should not have an auth_token cookie
      And I should not have a user id in my session store