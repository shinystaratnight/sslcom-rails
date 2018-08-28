class AddSslAccountToCsr < ActiveRecord::Migration
  def change
    add_reference :csrs, :ssl_account
    add_column  :csrs, :ref, :string
    add_column  :csrs, :friendly_name, :string
    add_column  :csrs, :modulus, :text
  end
end
