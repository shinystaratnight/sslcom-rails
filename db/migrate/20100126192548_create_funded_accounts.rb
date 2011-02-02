class CreateFundedAccounts < ActiveRecord::Migration
  def self.up
    create_table :funded_accounts, :force => true do |t|
      t.references  :ssl_account
      t.integer     :cents, :default=>0
      t.string      :state, :currency

      t.timestamps
    end
  end

  def self.down
    drop_table :funded_accounts
  end
end
