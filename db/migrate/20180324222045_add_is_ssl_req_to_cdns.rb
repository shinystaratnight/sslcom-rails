class AddIsSslReqToCdns < ActiveRecord::Migration
  def change
    add_column :cdns, :is_ssl_req, :boolean, default: false
  end
end
