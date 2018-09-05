class CertificateOrderTokensController < ApplicationController
  before_action :require_user, only: [:confirm]
  before_action :find_ssl_account, only: [:confirm]

  def create
    respond_to do |format|
      returnObj = {}

      if current_user
        ssl_account =
            if params[:ssl_slug]
              (current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts).find_by_acct_number(params[:ssl_slug]) ||
                  (current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts).find_by_ssl_slug(params[:ssl_slug])
            else
              current_user.ssl_account
            end
        if ssl_account.blank?
          returnObj['status'] = 'not_found_ssl_account'
        else
          co = (current_user.is_system_admins? ? CertificateOrder :
                    current_user.ssl_account.certificate_orders).find_by_ref(params[:certificate_order_ref])
          co_token = co.certificate_order_tokens.where(is_expired: false).first

          if co_token
            co_token.update_attribute(:due_date, 7.days.from_now)
          else
            co_token = CertificateOrderToken.new
            co_token.certificate_order = co
            co_token.ssl_account = ssl_account
            co_token.user = current_user
            co_token.is_expired = false
            co_token.due_date = 7.days.from_now
            co_token.token = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
            co_token.save!
          end

          OrderNotifier.certificate_order_token_send(co, co_token.token).deliver
          returnObj['status'] = 'success'
        end
      else
        returnObj['status'] = 'session_expired'
      end

      format.js { render :json => returnObj['status'].to_json }
    end
  end

  def confirm
    co_token = CertificateOrderToken.find_by_token(params[:token])
    if co_token
      if co_token.is_expired
        flash[:error] = "The page has expired or is no longer valid"
      elsif co_token.due_date < DateTime.now
        flash[:error] = "The page has expired or is no longer valid"
        co_token.update_attribute(:is_expired, true)
      else
        ssl_slug = co_token.certificate_order.ssl_account.acct_number || co_token.certificate_order.ssl_account.ssl_slug
        redirect_to generate_cert_certificate_order_path(ssl_slug, co_token.certificate_order.ref) and return
      end
    else
      flash[:error] = "Provided URL is incorrect."
    end
  end
end