// test/cypress/integrations/authentication_spec.js
describe('User authentication spec', function () {
  it('visit root', function () {
    // Clean database
    cy.exec('rake db:seed RAILS_ENV=test', { failOnNonZeroExit: false })

    // Visit root page
    cy.visit('https://localhost:5002');

    // Visit account page
    cy.contains("MY ACCOUNT")
      .click()

    // Load new account form
    cy.contains('Create a new account')
      .click()

    // Create user account
    cy.get('form').within(($form) => {
      cy.get('input[name="user[login]"]').type('cypress')
      cy.get('input[name="user[email]"]').type('cypress@test.ssl.com')
      cy.get('input[name="user[password]"]').type('Password123!')
      cy.get('input[name="user[password_confirmation]"]').type('Password123!')
      cy.get('input[name="tos"]').click()
      cy.root().submit()
    })

    // New user is redirected to Dashboard
    cy.contains('SSL.com Customer Dashboard')
  })
})
