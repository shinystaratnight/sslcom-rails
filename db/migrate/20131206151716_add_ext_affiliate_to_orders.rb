class AddExtAffiliateToOrders < ActiveRecord::Migration
  def self.up
    change_table    :orders do |t|
      t.string      :ext_affiliate_name
      t.string      :ext_affiliate_id
      t.boolean     :ext_affiliate_credited #was the affiliate credited? turn true once the order has been viewed
    end
  end

  def self.down
    change_table    :orders do |t|
      t.remove      :ext_affiliate_name, :ext_affiliate_id, :ext_affiliate_credited
    end
  end
end
