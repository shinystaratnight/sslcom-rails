class AddCardDeclinedToFundedAccounts < ActiveRecord::Migration
  def change
    add_column :funded_accounts, :card_declined, :text
  end
end
