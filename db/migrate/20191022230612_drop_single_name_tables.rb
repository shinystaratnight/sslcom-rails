class DropSingleNameTables < ActiveRecord::Migration
  def change
    drop_table  :blocklist
    drop_table  :caa_check
    drop_table  :physical_token
  end
end
