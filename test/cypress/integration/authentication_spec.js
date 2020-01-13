// test/cypress/integrations/authentication_spec.js
describe('User authentication spec', function () {
  before(() => {
    cy.app('clean')
    cy.appEval("Rails.cache.clear")
    cy.appFactories([
      ['create', 'user', 'owner', {login: 'token'}],
      ['create', 'user', 'owner', {login: 'tinman'}],
      ['create', 'user', 'owner', {email: 'cartman@gmail.com'}],
      ['create', 'user', 'super_user', {login: 'pickles'}],
      ['create_list', 'user', 5]
    ])
  })

  beforeEach(() => {
    cy.visit('/logout')
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
      cy.get('input[name="user[password]"]').type('Testing_ssl+1')
      cy.get('input[name="user[password_confirmation]"]').type('Testing_ssl+1')
      cy.get('input[name="tos"]').click()
      cy.root().submit()
    })

    // New User Is Redirected To Dashboard
    cy.contains('SSL.com Customer Dashboard')
  })

  it.skip('allows existing user to login and logout', function () {
    cy.visit('/user_session/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('cypress')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    cy.get('#content').contains('SSL.com Customer Dashboard')

    cy.contains('Logout').click()

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
    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="login"]').type('token')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('Customer login')
  })

  it('allows existing user to reset password using email', function () {
    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="email"]').type('cartman@gmail.com')
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

  it.skip('requires Duo 2FA when logging in as super_user', function () {
    cy.visit('/user_session/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('pickles')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    cy.location().should((loc) => {
      expect(loc.pathname).to.eq('/user_session/duo')
    })
  })

  it.skip('allows super_user to login as another user', function () {
    cy.app('super_user')

    cy.visit('/user_session/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('timmy')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    cy.visit('/account')
    cy.get('#content').contains('Customer Dashboard')
  })
})
