class AddTeamMaxToUsers < ActiveRecord::Migration
  def change
    add_column :users, :max_teams, :integer
    add_column :users, :main_ssl_account, :integer
    add_index  :users, :default_ssl_account

    User.update_all(max_teams: 5)
  end
end
