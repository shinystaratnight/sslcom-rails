class AddNickNameToU2fs < ActiveRecord::Migration
  def change
    add_column :u2fs, :nick_name, :string
  end
end
