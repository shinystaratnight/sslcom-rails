class AddIndexToDelayedJobs < ActiveRecord::Migration
  def change
    change_column :delayed_jobs, :handler, :longtext, :null => false
    change_column :delayed_jobs, :last_error, :longtext

    add_index :delayed_jobs, [:queue], :name => 'delayed_jobs_queue'
    add_index :delayed_jobs, [:priority, :run_at, :locked_by]
  end
end
