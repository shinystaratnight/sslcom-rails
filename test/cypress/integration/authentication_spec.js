// test/cypress/integrations/authentication_spec.js
describe('My First Test', function () {
  it('visit root', function () {
    // This calls to the backend to prepare the application state
    // cy.appFactories([
    //   ['create_list', 'post', 10],
    //   ['create', 'post', {title: 'Hello World'} ]
    // ])

    // Visit the application under test
    cy.visit('/');

    cy.contains("My ACCOUNT")

    // Accessing result
    // cy.appFactories([
    //   ['create', 'invoice', {
    //     paid: false
    //   }]
    // ]).then((records) => {
    //   cy.visit(`/invoices/${records[0].id}`);
    // });
  })
})
