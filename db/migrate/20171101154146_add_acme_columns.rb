class AddAcmeColumns < ActiveRecord::Migration
  def self.up
    change_table :certificate_orders, force: true do |t|
      t.string  :validation_type
      t.string  :acme_account_id
    end
    change_table :certificate_names, force: true do |t|
      t.string  :acme_account_id
    end
    change_table :ssl_accounts, force: true do |t|
      t.string  :issue_dv_no_validation
    end
  end

  def self.down
    change_table :certificate_orders, force: true do |t|
      t.remove  :validation_type
      t.remove  :acme_account_id
    end
    change_table :certificate_names, force: true do |t|
      t.remove  :acme_account_id
    end
    change_table :ssl_accounts, force: true do |t|
      t.remove  :issue_dv_no_validation
    end
  end
end
