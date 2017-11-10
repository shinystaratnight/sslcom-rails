class CreateDbs < ActiveRecord::Migration
  def change
    create_table :dbs do |t|
      t.string :name,:host,:username,:password,:name
    end
  end
end
