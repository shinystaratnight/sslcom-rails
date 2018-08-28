class CreateRegisteredAgents < ActiveRecord::Migration
  def change
    create_table :registered_agents do |t|
      t.string  :ref, :null => false
      t.references  :ssl_account, :null => false
      t.string  :ip_address, :null => false
      t.string  :mac_address, :null => false
      t.string  :agent, :null => false
      t.string  :friendly_name
      t.references :requester
      t.datetime  :requested_at
      t.references :approver
      t.datetime  :approved_at
      t.string  :workflow_status, :null => false
      t.timestamps
    end
  end
end
