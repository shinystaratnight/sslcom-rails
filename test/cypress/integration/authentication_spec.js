// test/cypress/integrations/authentication_spec.js
describe('User authentication spec', function () {
  beforeEach(() => {
    cy.app('clean')
    cy.request('DELETE', '/user_session')
    cy.log('before each executed')
  })

  it('allows user to register and login', function () {
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
    cy.appFactories([
      ['create', 'user', {
        login: 'existing'
      }]
    ])

    // Go To Login Page
    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('existing')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })


    // User Is Redirected To Dashboard
    cy.get('#content')
      .should('not.contain', 'Customer login')
      .contains('SSL.com Customer Dashboard')

    // Logout User
    cy.contains('Logout')
      .click()

    // Redirected to Login Page
    cy.contains('Customer login')
  })

  it('fails gracefully when attempting to reset password with nonexistent login', function () {
    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="login"]').type('nonexistent')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('No user was found with that login')
  })

  it('allows existing user to reset password using login', function () {
    cy.appFactories([
      ['create', 'user', {
        login: 'existing'
      }]
    ])

    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="login"]').type('existing')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('Customer login')
  })

  it('allows existing user to reset password using email', function () {
    cy.appFactories([
      ['create', 'user', {
        email: 'existing@ssl.com'
      }]
    ])

    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="email"]').type('existing@ssl.com')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('Customer login')
  })

  it('fails gracefully when attempting to reset a password with nonexistent email', function () {
    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="email"]').type('nonexistent@ssl.com')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('No user was found with that email')
  })

  it('requires Duo 2FA when logging in as super_user', function () {
    cy.app('super_user')

    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('superuser1')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    // Prompted for Duo 2FA
    cy.location().should((loc) => {
      expect(loc.pathname).to.eq('/user_session/duo')
    })
  })
})
