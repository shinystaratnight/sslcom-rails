Feature: Sandbox for testing

    Scenario Outline: Registered user deposits funds
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
