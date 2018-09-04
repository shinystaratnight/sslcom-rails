class CreateContactValidationHistory < ActiveRecord::Migration
  def change
    create_table :contact_validation_histories do |t|
      t.belongs_to :contact, index: true, null: false
      t.belongs_to :validation_history, index: true, null: false
      t.timestamps
    end

    add_index :contact_validation_histories, [:contact_id, :validation_history_id], name: 'index_cont_val_histories_on_contact_id_and_validation_history_id'
  end
end
