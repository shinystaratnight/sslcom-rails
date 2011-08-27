#use rack_test for inline and selenium for remote
#@rack_test
@selenium @no-txn @remote
@setup_certificates @firebug



Feature: Permissions to pages
  As a user
  I want to be able to access certain pages while restricting others from accessing those pages
  So that my security is not compromised from unintended or illicit use

  Scenario: User can must sent validation requests from one of the selected email addresses
    Given a registered user Fred exists
      And Fred has a new dv certificate order at the validation prompt stage
      And I login as Fred
     When I request domain control validation be sent during checkout
     Then a domain control validation request should be sent

  Scenario: User can send validation requests for a new order to other users
    Given a registered user Fred exists
      And Fred has a new dv certificate order at the validation prompt stage
      And I login as Fred
     When I request domain control validation from somebody@example.com
#     Then somebody should receive a request email
#      And somebody should have access to the validation submittal page
#      And somebodyelse should not have access to the validation submittal page

  Scenario: User can send validation requests for an existing order to other users
    Given a registered user Fred exists
      And Fred has a certificate order
      And I'm logged in as Fred
     When I request domain control validation from somebody@example.com
     Then somebody should receive a request email
      And somebody should have access to the validation submittal page
      And somebodyelse should not have access to the validation submittal page

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