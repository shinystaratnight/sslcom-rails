class CreateSystemAudits < ActiveRecord::Migration
  def self.up
    create_table :system_audits, force: true do |t|
      t.references :owner, :polymorphic => true
      t.references :target, :polymorphic => true
      t.text    :notes
      t.string  :action
      t.timestamps
    end
  end

  def self.down
    drop_table :system_audits
  end
end
