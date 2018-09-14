class ScanLogsController < ApplicationController
  before_action :find_ssl_account
  before_action :set_row_page, only: [:index]

  def index
    @scan_history_list = @ssl_account.notification_groups.find(params[:notification_group_id]).scan_logs.paginate(@p)
  end

  private
    def set_row_page
      preferred_row_count = current_user.preferred_scan_log_row_count
      @per_page = params[:per_page] || preferred_row_count.or_else("10")
      ScanLog.per_page = @per_page if ScanLog.per_page != @per_page

      if @per_page != preferred_row_count
        current_user.preferred_scan_log_row_count = @per_page
        current_user.save(validate: false)
      end

      @p = {page: (params[:page] || 1), per_page: @per_page}
    end
end