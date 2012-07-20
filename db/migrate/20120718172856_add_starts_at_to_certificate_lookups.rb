class AddStartsAtToCertificateLookups < ActiveRecord::Migration
  def self.up
    change_table    :certificate_lookups do |t|
      t.datetime    :starts_at
    end
  end

  def self.down
    change_table    :certificate_lookups do |t|
      t.remove      :starts_at
    end
  end
end
