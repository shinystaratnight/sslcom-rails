#use driver @rack_test for inline and @selenium for remote
#when changing drivers, be sure to change DatabaseCleaner.strategy in db_cleaner.rb
#also all comments must appear before tags with no comments in-between tags
#email tests do not work with remote selenium
#@rack_test
@selenium
@remote
@firebug
@setup_certificates

Feature: Permissions to pages
  As a user
  I want to be able to access certain pages while restricting others from accessing those pages
  So that my security is not compromised from unintended or illicit use

  @passed_selenium_remote @passed_rack_test
  Scenario: User must sent validation requests from one of the selected email addresses
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
  @passed_rack_test
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

  @passed_selenium_remote
  Scenario: Person who received a validation request must register to supply validation
    Given a registered user Fred exists
      And Fred has a completed but unvalidated dv certificate order
      And somebody@example.com received a domain control validation request from Fred
     When somebody@example.com attempts to supply domain control validation
     Then somebody@example.com should be required to register

  @passed_selenium_remote
  Scenario: Person who received a validation request and is registered should be able to supply validation
    Given a registered user Fred exists
      And a registered user Susan exists
      And Fred has a completed but unvalidated dv certificate order
      And Susan received a domain control validation request from Fred
      And I login as Susan
     When I send domain control validation verification
     Then domain control validation confirmation should appear
      And domain control validation request should be created

  @passed_rack_test @passed_selenium_remote
  Scenario: Person who received a validation request and is registered should be able to forward validation
    Given a registered user Fred exists
      And a registered user Susan exists
      And Fred has a completed but unvalidated dv certificate order
      And Susan received a domain control validation request from Fred
      And I login as Susan
     When I forward domain control validation request to somebody@example.com
      And "somebody@example.com" opens the email
     Then "somebody@example.com" should have an email
      And they should see "Validation Request for SSL.com Certificate lobby.sb.betsoftgaming.com" in the email subject
      And they should see "Additional validation information is required" in the email body
      And they should see "lobby.sb.betsoftgaming.com" in the email body

  @passed_rack_test @passed_selenium_remote
  Scenario: Person who did not receive a validation request should not be able to supply validation
    Given an activated user Fred exists
      And an activated user Nosey exists
      And an activated user Susan exists
      And Fred has a completed but unvalidated dv certificate order
      And Susan received a domain control validation request from Fred
      And I login as Nosey
     When I attempt to supply domain control validation
     Then I should be denied
