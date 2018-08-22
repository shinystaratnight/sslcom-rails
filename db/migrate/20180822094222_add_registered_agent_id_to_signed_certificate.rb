class AddRegisteredAgentIdToSignedCertificate < ActiveRecord::Migration
  # def change
  # end

  def self.up
    change_table  :signed_certificates do |t|
      t.references  :registered_agent
    end
  end

  def self.down
    change_table  :signed_certificates do |t|
      t.remove  :registered_agent
    end
  end
end
