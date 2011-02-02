class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.references :ssl_account
      t.string    :login,               :null => false                # optional, you can use email instead, or both
      t.string    :email,               :null => false                # optional, you can use login instead, or both
      t.string    :crypted_password                                   # optional, see below
      t.string    :password_salt                                      # optional, but highly recommended
      t.string    :persistence_token,   :null => false                # required
      t.string    :single_access_token, :null => false                # optional, see Authlogic::Session::Params
      t.string    :perishable_token,    :null => false                # optional, see Authlogic::Session::Perishability
      t.string    :status

      # Optional
      t.string  :first_name
      t.string  :last_name
      t.string  :phone
      t.string  :organization
      t.string  :address1
      t.string  :address2
      t.string  :address3
      t.string  :po_box
      t.string  :postal_code
      t.string  :city
      t.string  :state
      t.string  :country
      t.string  :phone
      t.string  :ext
      t.string  :fax
      t.string  :website
      t.string  :tax_number
      
      # Magic columns, just like ActiveRecord's created_at and updated_at. These are automatically maintained by Authlogic if they are present.
      t.integer   :login_count,         :null => false, :default => 0 # optional, see Authlogic::Session::MagicColumns
      t.integer   :failed_login_count,  :null => false, :default => 0 # optional, see Authlogic::Session::MagicColumns
      t.datetime  :last_request_at                                    # optional, see Authlogic::Session::MagicColumns
      t.datetime  :current_login_at                                   # optional, see Authlogic::Session::MagicColumns
      t.datetime  :last_login_at                                      # optional, see Authlogic::Session::MagicColumns
      t.string    :current_login_ip                                   # optional, see Authlogic::Session::MagicColumns
      t.string    :last_login_ip                                      # optional, see Authlogic::Session::MagicColumns
      t.boolean   :active, :default => false, :null => false
      t.string    :openid_identifier

      t.timestamps
    end
    add_index :users, :perishable_token
    add_index :users, :email
  end

  def self.down
    drop_table :users
  end
end
