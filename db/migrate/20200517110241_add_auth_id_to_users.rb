class AddAuthIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :authy_user, :string, foreign_key: false
  end
end
