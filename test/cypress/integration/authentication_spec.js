// test/cypress/integrations/authentication_spec.js
describe('User authentication spec', function () {
  beforeEach(() => {
    cy.appEval("User.connection.truncate(User.table_name)")
    cy.log('users table reset')
    cy.request('DELETE', '/user_session')
    cy.log('user session destroyed')
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
      cy.get('input[name="user[login]"]').type('chef')
      cy.get('input[name="user[email]"]').type('chef@test.ssl.com')
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
        login: 'stan'
      }]
    ])

    // Go To Login Page
    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('stan')
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
      cy.get('input[name="login"]').type('skeeter')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('No user was found with that login')
  })

  it('allows existing user to reset password using login', function () {
    cy.appFactories([
      ['create', 'user', {
        login: 'liane'
      }]
    ])

    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="login"]').type('liane')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('Customer login')
  })

  it('allows existing user to reset password using email', function () {
    cy.appFactories([
      ['create', 'user', {
        email: 'cartman@ssl.com'
      }]
    ])

    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="email"]').type('cartman@ssl.com')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('Customer login')
  })

  it('fails gracefully when attempting to reset a password with nonexistent email', function () {
    cy.visit('/password_resets/new')

    cy.get('form').within(($form) => {
      cy.get('input[name="email"]').type('token@ssl.com')
    })
    cy.get('.password_resets_btn').click()
    cy.contains('No user was found with that email')
  })

  it('requires Duo 2FA when logging in as super_user', function () {
    cy.appFactories([
      ['create', 'user', {
        login: 'kenny'
      }]
    ])
    cy.appEval("User.find_by(name: 'kenny').assign_roles([Role.find_or_create_by(name: 'super_user')])")
    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('kenny')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    // Prompted for Duo 2FA
    cy.location().should((loc) => {
      expect(loc.pathname).to.eq('/user_session/duo')
    })
  })

  it('allows super_user to login as another user', function () {
    cy.appFactories([
      ['create', 'user', {
        login: 'timmy'
      }],
      ['create_list', 'user', 5]
    ])
    cy.appEval("User.find_by(login: 'timmy').make_admin")

    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('timmy')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    let session
    cy.getCookie('_my_app_session')
      .then((c) => {
        session = c
      })

    cy.log(session)

    cy.visit('/account')
    cy.get('#content')
      .should('not.contain', 'Customer login')
      .contains('Customer Dashboard')
  })
})
