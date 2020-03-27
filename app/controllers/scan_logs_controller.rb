class ScanLogsController < ApplicationController
  before_action :find_ssl_account
  before_action :global_set_row_page, only: [:index]

  def index
    @notification_group = @ssl_account.notification_groups.find(params[:notification_group_id])
    @scan_history_list = @notification_group.scan_logs.order('created_at desc').paginate(@p)
  end

end
