class DropClientApplications < ActiveRecord::Migration
  def change
    drop_table :client_applications
  end if table_exists?(:client_applications)
end
