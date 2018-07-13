class CreateNotificationGroupsSubjects < ActiveRecord::Migration
  # def change
  #   create_table :notification_groups_subjects do |t|
  #   end
  # end

  def self.up
    create_table :notification_groups_subjects, force: true do |t|
      t.string      :domain_name                # user if subjectable is blank
      t.integer     :notification_group_id
      t.integer     :subjectable_id             # can be id of certificate_order or certificate_content or certificate_name
      t.string      :subjectable_type           # can be 'CertificateOrder' or 'CertificateContent' or 'CertificateName'
      t.timestamps
    end

    add_index :notification_groups_subjects, :notification_group_id
  end

  def self.down
    drop_table :notification_groups_subjects
  end
end
