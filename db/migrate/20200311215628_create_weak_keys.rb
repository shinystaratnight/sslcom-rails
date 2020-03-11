class CreateWeakKeys < ActiveRecord::Migration
  def change
    create_table :weak_keys do |t|
      t.string    :sha1_hash
      t.string    :algorithm
      t.integer   :size
    end
    add_index   :weak_keys, :sha1_hash
  end
end
