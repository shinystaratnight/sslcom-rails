class AddExpirationDateToScanLogs < ActiveRecord::Migration
  def change
    add_column :scan_logs, :expiration_date, :datetime
  end
end
