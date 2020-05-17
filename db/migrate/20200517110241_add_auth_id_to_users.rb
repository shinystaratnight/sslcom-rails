class AddAuthIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :authy_user_id, :string, foreign_key: false
  end
end
