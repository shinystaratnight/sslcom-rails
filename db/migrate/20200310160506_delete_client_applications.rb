class DeleteClientApplications < ActiveRecord::Migration
  def change
    drop_table :client_applications
  end
end
