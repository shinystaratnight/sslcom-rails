class CreateVisitorTokens < ActiveRecord::Migration
  def self.up
    create_table  :visitor_tokens do |t|
      t.references  :user
      t.references  :affiliate
      t.string      :guid
    end
  end

  def self.down
    drop_table    :visitor_tokens
  end
end
