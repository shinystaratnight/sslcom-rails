class AddDomainsToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :domains, :text # which domains covered by LockedRegistrant
  end
end