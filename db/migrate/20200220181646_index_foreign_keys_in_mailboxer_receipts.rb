class IndexForeignKeysInMailboxerReceipts < ActiveRecord::Migration
  def change
    add_index :mailboxer_receipts, :message_id
  end
end
