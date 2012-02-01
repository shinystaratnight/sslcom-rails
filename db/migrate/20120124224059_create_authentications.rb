class CreateAuthentications < ActiveRecord::Migration
      def self.up
          create_table :authentications, force: true do |t|
              t.integer :user_id
              t.string :provider
              t.string :uid
              t.string :email
              t.string :first_name
              t.string :last_name
              t.string :nick_name
              t.timestamps
          end
      end

      def self.down
          drop_table :authentications
      end
  end


