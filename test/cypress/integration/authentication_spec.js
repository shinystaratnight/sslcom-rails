// test/cypress/integrations/authentication_spec.js
describe('User authentication spec', function () {
  it('allows user to register and login', function () {
    // Clean Database
    cy.app('clean')

    // Visit Root Page
    cy.visit('/');

    // Visit Account Page
    cy.contains("MY ACCOUNT")
      .click()

    // Go To Login Page
    cy.contains('Create a new account')
      .click()

    // Create User Account
    cy.get('form').within(($form) => {
      cy.get('input[name="user[login]"]').type('cypress')
      cy.get('input[name="user[email]"]').type('cypress@test.ssl.com')
      cy.get('input[name="user[password]"]').type('Password123!')
      cy.get('input[name="user[password_confirmation]"]').type('Password123!')
      cy.get('input[name="tos"]').click()
      cy.root().submit()
    })

    // New User Is Redirected To Dashboard
    cy.contains('SSL.com Customer Dashboard')
  })

  it('allows existing user to login and logout', function () {
    // Go To Login Page
    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('cypress')
      cy.get('input[name="user_session[password]"]').type('Password123!')
      cy.root().submit()
    })

    // User Is Redirected To Dashboard
    cy.contains('SSL.com Customer Dashboard')

    // Logout User
    cy.contains('Logout')
      .click()

    // Redirected to Login Page
    cy.contains('Customer login')
  })
})
