class AddScanGroupToScanLogs < ActiveRecord::Migration
  def change
    add_column  :scan_logs, :scan_group, :integer
  end
end
