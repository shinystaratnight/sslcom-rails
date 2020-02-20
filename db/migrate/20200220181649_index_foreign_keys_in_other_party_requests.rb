class IndexForeignKeysInOtherPartyRequests < ActiveRecord::Migration
  def change
    add_index :other_party_requests, :other_party_requestable_id
  end
end
