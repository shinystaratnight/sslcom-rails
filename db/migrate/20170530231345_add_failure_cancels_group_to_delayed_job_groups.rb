class AddFailureCancelsGroupToDelayedJobGroups < ActiveRecord::Migration
  def change
    add_column :delayed_job_groups, :failure_cancels_group, :boolean, default: true, null: false
  end
end
