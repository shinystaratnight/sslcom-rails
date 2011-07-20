class CreateOtherPartyRequests < ActiveRecord::Migration
  def self.up
    create_table :other_party_requests do |t|
      t.references  :other_party_requestable, polymorphic: true
      t.references  :user
      t.text      :email_addresses
      t.string    :identifier
      t.datetime  :sent_at

      t.timestamps
    end
  end

  def self.down
    drop_table :other_party_requests
  end
end
