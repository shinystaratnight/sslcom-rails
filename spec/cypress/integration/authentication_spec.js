// spec/cypress/integrations/authentication_spec.js
describe('User authentication spec', function () {
  before(() => {
    cy.app('clean')
  })

  it('allows user to register and login', function () {
    cy.visit('/user_session/new')
    cy.contains('Create a new account').click()

    cy.get('form').within(($form) => {
      cy.get('input[name="user[login]"]').type('cypress')
      cy.get('input[name="user[email]"]').type('cypress@test.ssl.com')
      cy.get('input[name="user[password]"]').type('Testing_ssl+1')
      cy.get('input[name="user[password_confirmation]"]').type('Testing_ssl+1')
      cy.get('input[name="tos"]').click()
      cy.root().submit()
    })

    cy.contains('SSL.com Customer Dashboard')
    cy.visit('/logout')
  })

  it('allows existing user to login and logout', function () {
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('cypress')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    cy.get('#content').contains('SSL.com Customer Dashboard')

    cy.contains('Logout').click()

    cy.contains('Customer login')
    cy.visit('/logout')
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
      ['create', 'user', {login: 'token'}]
    ])
    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="login"]').type('token')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('Customer login')
  })

  it('allows existing user to reset password using email', function () {
    cy.appFactories([
      ['create', 'user', {email: 'cartman@gmail.com'}]
    ])
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

  it('requires Duo 2FA when logging in as super_user', function () {
    cy.appFactories([
      ['create', 'user', 'super_user', {login: 'pickles'}],
    ])

    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('pickles')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    // Prompted for Duo 2FA
    cy.location().should((loc) => {
      expect(loc.pathname).to.eq('/user_session/duo')
    })
  })

  it('allows sysadmin to login as another user', function () {
    cy.appFactories([['create', 'user', 'sysadmin', {login: 'tyson' }]]).then((_results) => {
      cy.setCookie('skip_duo', 'true')
      cy.visit('/user_session/new')

      cy.get('form').within(($form) => {
        cy.get('input[name="user_session[login]"]').type('tyson')
        cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
        cy.root().submit()
      })

      cy.location().should((loc) => {
        expect(loc.pathname).to.contain('/team')
        expect(loc.pathname).to.contain('/account')
      })
      cy.get('#manage_certificates').click()
      cy.get('td.dropdown').eq(2).click()
      cy.contains('login as').click()
      cy.contains('pickles')
    })
  })
})
