Feature: Shopping
    As an customer
    I want to be able to buy clips
    So that I can enjoy them

    Scenario: There is a shopping cart
        Given I am not logged in
          And there is an empty shopping cart

    Scenario: Anonymous user adds items 
        Given I am not logged in
          And there is an empty shopping cart
          And I add some items to the cart
        When I click the 'link' with 'cart_size' 'id'
        Then I should be at path '/orders/show_cart/current'
          And I should see 'Total'
          And I should see '$21.97 USD' in 'cart_total'

    Scenario: Anonymous user adds items then clicks 'remove all items' button
        Given I am not logged in
          And there is an empty shopping cart
          And I add some items to the cart
        When I click the 'link' with 'cart_size' 'id'
          And I click the 'button' with 'empty_cart' 'id'
        Then I should be at path '/orders/show_cart/current'
          And I should see 'Total'
          And I should see '$0.00 USD' in 'cart_total'

    Scenario: Anonymous user adds items then removes individual items
        Given I am not logged in
          And there is an empty shopping cart
          And I add some items to the cart
        When I click the 'link' with 'cart_size' 'id'
          And I click the 'link' with 'release_45' 'id'
        Then I should be at path '/orders/show_cart/current'
          And I should see '$14.98 USD' in 'cart_total'
          And I should see '2' in 'cart_size'

    Scenario: Anonymous user check out
        Given I am not logged in
          And there is an empty shopping cart
        When I add some items to the cart
          And I click the 'link' with 'cart_size' 'id'
          And I click the 'link' with 'Checkout' 'text'
          And I should be directed to the login path
          And I should see '» Click here to sign up' in the 'link' with attribute 'href' == '/signup'
          And I am prompted with "have an account?"
          And I am prompted with "Log in"
          And I login with username 'aaron' and password 'test'
          And I should be at path 'secure/allocate_funds_for_order'
          And I click the 'link' with 'Click here to add a new credit card'
          And I enter my profile information
          |first_name|last_name|address1|address2|city    |state|country           |postal_code|phone       |
          |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States     |77777      |123-123-1234|

          And I enter my credit card payment information
          |card_type|card_number  |exp_mo|exp_yr|security_code|result_code|
          |Visa     |4222222222222|8    |2010  |000          |01         |

          And I click the submit button

          Then I should see "(TEST) The transaction was successful"
            And I should see "Order Number: xxxxxxx"
            And I should see "xxxx-xxxx-xxxx-2222"
            And I should see a "click here to view/download clips" "link"

    Scenario Outline: Registered user loads cart then deposits funds to prove order does not "bleed over" into the deposit
      Given the user with username "<user>" and password "<pass>" is logged in
        And there is an empty shopping cart
      When he adds some items to the cart
        And "<user>" makes a deposit
          |first_name|last_name|address1|address2|city    |state|country      |postal_code|phone       |card_type|card_number     |exp_mo|exp_yr|security_code|amount|result_code|
          |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States|77777      |123-123-1234|Visa     |5588280019102398|8     |2010  |000          |$25.00|01         |
      Then he should see "Amount: $25.00 USD"
        And he should not see "Order Details"

    Examples:
      |user |pass|
      |aaron|test|

    #unfinished

    Scenario: Anonymous user check out
        Given I am not logged in
          And there is an empty shopping cart
        When I add some items to the cart
          And I click the 'link' with 'Checkout' 'text'
        Then I should be at path '/orders/show_cart/current'
          And I should see '$14.98 USD' in 'cart_total'
          And I should see '2' in 'cart_size'



    Scenario: Anonymous user check out
        Given I am not logged in
        When I add the "first" video clip to my cart
            And I click the "my cart" "link"
            And I click the "check out" "link"
            And I am prompted to "register"
            But I am also prompted to "login"
            And I register
            And I login
            And I am redirected to the payment page
            And I enter my profile information
            |first_name|last_name|address1|address2|city    |state|country           |postal_code|phone       |
            |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States     |77777      |123-123-1234|

            And I enter my credit card payment information
            |card_type|card_number  |exp_mo|exp_yr|security_code|result_code|
            |Visa     |4222222222222|8    |2010  |000          |01         |

            And I click the submit button

            Then the payment gateway should return result
            |code|
            |01  |

              And I should see "(TEST) The transaction was successful"
              And I should see "Order Number: xxxxxxx"
              And I should see "xxxx-xxxx-xxxx-2222"
              And I should see a "click here to view/download clips" "link"

    Scenario: Registered user checks out
        Given the user with username "nutty" and password "jama1kama1" is logged in
        When he visits the payment page
          And he enters his profile information
          |first_name|last_name|address1|address2|city    |state|country           |postal_code|phone       |
          |Joe       |Smith    |123 Rd  |Ste 11  |New York|NY   |United States     |77777      |123-123-1234|

          And he enters his credit card payment information
          |card_type|card_number  |exp_mo|exp_yr|security_code|result_code|
          |Visa     |4222222222222|8    |2010  |000          |01         |

          And he clicks the submit button

        Then he should see result
        |code|
        |01  |