// test/cypress/integrations/authentication_spec.js
describe('User authentication spec', function () {
  beforeEach(() => {
    cy.visit('/logout')
  })

  it('removes users from previous tests', function(){
    cy.appEval("User.destroy_all")
  })

  it('allows user to register and login', function () {
    cy.contains('Create a new account').click()

    cy.get('form').within(($form) => {
      cy.get('input[name="user[login]"]').type('chef')
      cy.get('input[name="user[email]"]').type('chef@test.ssl.com')
      cy.get('input[name="user[password]"]').type('Testing_ssl+1')
      cy.get('input[name="user[password_confirmation]"]').type('Testing_ssl+1')
      cy.get('input[name="tos"]').click()
    })
    cy.get('#next_submit').click()

    cy.contains('SSL.com Customer Dashboard')
  })

  it('allows existing user to login and logout', function () {
    cy.appFactories([
      ['create', 'user', {
        login: 'randy'
      }]
    ])

    cy.visit('/');

    cy.contains("MY ACCOUNT").click()

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input#user_session_login').type('randy')
      cy.get('input#user_session_password').type('Testing_ssl+1')
    })

    cy.get('#next_submit').click()

    // User Is Redirected To Dashboard
    cy.get('#content').contains('SSL.com Customer Dashboard')

    // // Logout User
    // cy.contains('Logout').click()

    // // Redirected to Login Page
    // cy.contains('Customer login')
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
    cy.appEval("User.find_by(login: 'kenny').make_super_user")

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
    cy.setCookie('skip_duo', 'true')
    cy.appFactories([
      ['create', 'user', {
        login: 'timmy'
      }],
      ['create_list', 'user', 5]
    ])
    cy.appEval("User.find_by(login: 'timmy').make_super_user")
    cy.visit('/user_session/new')

    // Fill In And Submit Login Form
    cy.get('form').within(($form) => {
      cy.get('input[name="user_session[login]"]').type('timmy')
      cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
      cy.root().submit()
    })

    // cy.visit('/account')
    cy.get('#content').contains('Admin Dashboard')
  })
})
