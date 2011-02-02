Feature: Account Maintenance
    As an customer
    I have to maintain my required account minimum
    So that I can access the resources on the site

    Scenario: First-time user orders below the minimum amount
        Given he is logged in
          And he has $0 in his Nutcash account
          And he has the first 2 releases in his cart that totals less than $19.95
        When he checks out
          And he goes to the billing profile information page
        Then he can choose from several amounts to deposit into his Nutcash account

    Scenario: User orders above the minimum amount
        Given he is logged in
          And he has $0 in his Nutcash account
          And he has the first 2 releases in his cart that totals more than $19.95
        When he checks out
          And he goes to the billing profile information page
        Then he can choose from several amounts to deposit into his Nutcash account

    Scenario: User's cash amount in cart exceeds his Nutcash amount
        Given he is logged in
          And he has $5 in his Nutcash account
          And he has the first 2 releases in his cart that totals $11.95
        When he checks out
          And he goes to the billing profile information page
        Then he can choose from blocks of $10 to deposit into his Nutcash account
          And the blocks start at next multiple of $10 above the cart amount

   Scenario: If the total amount in your cart exceeds the amount in your
    Nutcash account you will be prompted to deposit funds in blocks of $10
    starting with a value higher than your cart amount

    Examples:
    |cart_amount|minimum_amount|
    |$15.00     |$20.00        |
    |$22.00     |$30.00        |
    |$35.00     |$40.00        |
    |$55.00     |$60.00        |

   Scenario: ??Not sure about this?? If the difference between the amount in your cart and the amount in your
    Nutcash account is less than $10, you will be prompted to deposit from a bracketed amount (19.95, 49.95, 99.95, 199.95)

   Scenario: You can select auto charge and a block triggered when your
    account goes below $10 or when the amount in the cart exceeds the amount
    in your Nutcash account.



