class AddCreatedPageToNotificationGroupsSubjects < ActiveRecord::Migration
  def change
    add_column :notification_groups_subjects, :created_page, :string
  end
end
