class CreateWeakKeys < ActiveRecord::Migration
  def change
    create_table :weak_keys do |t|
      t.string    :sha1_hash, length: 20
      t.string    :algorithm
      t.integer   :size
    end
    add_index   :weak_keys, :sha1_hash
  end unless table_exists?(:weak_keys)
end
