class GiveScheduleValueDefaultValueOnSchedules < ActiveRecord::Migration
  def change
    change_column :schedules, :schedule_value, :string, :default => '2'
  end
end
