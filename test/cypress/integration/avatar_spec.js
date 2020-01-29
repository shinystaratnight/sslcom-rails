// test/cypress/integrations/authentication_spec.js
describe('Avatar spec', function () {
  before(() => {
    cy.app('clean')
  })

  it('allows user to upload avatar image', function () {
    const fileName = 'idris.jpg';

    cy.appFactories([['create', 'user', 'owner', { login: 'avatar_user'}]]).then((_results) => {
      cy.setCookie('skip_duo', 'true')
      cy.visit('/user_session/new')

      cy.get('form').within(($form) => {
        cy.get('input[name="user_session[login]"]').type('avatar_user')
        cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
        cy.root().submit()
      })
      cy.get("#uploadModal button[data-dismiss='modal']").should('not.be.visible')
      cy.contains('Add photo').click();
      cy.get("#uploadModal button[data-dismiss='modal']").should('be.visible')
      cy.fixture(fileName).then(fileContent => {
        cy.get('#uploadModal input#file').upload({ fileContent, fileName, mimeType: 'image/jpeg' });
        cy.get('#uploadModal input#file').trigger('change');
      })
      cy.get('#uploadModal input#file').trigger('change');

      cy.contains("#uploadModal button.btn.btn-primary[data-dismiss='modal']").click()
    })
  })
})
