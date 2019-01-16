class AddDomainsToContact < ActiveRecord::Migration
  def change
    add_column :contact, :domains, :text # which domains covered by LockedRegistrant
  end
end
