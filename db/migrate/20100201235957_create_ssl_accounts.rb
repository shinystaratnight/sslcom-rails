class CreateSslAccounts < ActiveRecord::Migration
  def self.up
    create_table :ssl_accounts do |t|
      t.string  :acct_number
      t.string  :roles, :default => "--- []"
      t.timestamps
    end
  end

  def self.down
    drop_table :ssl_accounts
  end
end
