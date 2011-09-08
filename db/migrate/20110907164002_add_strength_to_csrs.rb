class AddStrengthToCsrs < ActiveRecord::Migration
  def self.up
    change_table :csrs do |t|
      t.text    :subject_alternative_names
      t.integer :strength
      t.boolean :challenge_password
    end
  end

  def self.down
    change_table :csrs do |t|
      t.remove :subject_alternative_names
      t.remove :strength
      t.remove :challenge_password
    end
  end
end
