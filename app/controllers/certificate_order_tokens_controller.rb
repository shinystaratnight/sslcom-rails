class CertificateOrderTokensController < ApplicationController
  before_action :require_user, only: [:confirm]
  before_action :find_ssl_account, only: [:confirm]

  def create
    respond_to do |format|
      returnObj = {}

      if current_user
        team_account =
            if params[:ssl_slug]
              (current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts).find_by_acct_number(params[:ssl_slug]) ||
                  (current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts).find_by_ssl_slug(params[:ssl_slug])
            else
              current_user.ssl_account
            end
        if team_account.blank?
          returnObj['status'] = 'not_found_ssl_account'
        else
          co = current_user.certificate_order_by_ref(params[:certificate_order_ref])

          # Finding and Setting Assignee to Certificate Order
          # and assign individual_certificate role to assignee in scope of the team.
          email_address = co.get_download_cert_email
          assignee = User.find_by_email(email_address)
          
          unless co.certificate.is_smime_or_client?
            co.update_attribute(:assignee, assignee) unless co.assignee == assignee

            if assignee && !assignee.duplicate_role?(Role.get_individual_certificate_id, co.ssl_account)
              assignee.ssl_accounts << co.ssl_account
              assignee.ssl_account_users.where(ssl_account_id: co.ssl_account.id).first.update_attribute(:approved, true)
              assignee.set_roles_for_account(co.ssl_account, [Role.get_individual_certificate_id])
            end
          end

          # create / update certificate order token table
          # co_token = co.certificate_order_tokens.where(status: nil, is_expired: false).last
          co_token = co.generate_certificate_order_token
          if co_token && !co_token.is_expired
            co_token.update_attributes(due_date: 7.days.from_now, user: assignee)
          else
            co_token = CertificateOrderToken.new
            co_token.certificate_order = co
            co_token.ssl_account = team_account
            co_token.user = assignee
            co_token.is_expired = false
            co_token.due_date = 7.days.from_now
            co_token.token = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
            co_token.save!
          end

          if params['send_email_link'].blank? || (!params['send_email_link'].blank? && params['send_email_link'] == 'true')
            # Notifying to assignee
            OrderNotifier.certificate_order_token_send(co, co_token.token).deliver
            returnObj['send_email'] = 'true'
          else
            returnObj['send_email'] = 'false'
          end

          if !params['copy_act_link'].blank? && (params['copy_act_link'] == 'true')
            returnObj['act_link'] = confirm_url(co_token.token)
          else
            returnObj['act_link'] = 'false'
          end

          co.certificate_content.validate! if co.certificate_content.issued?

          returnObj['status'] = 'success'
        end
      else
        returnObj['status'] = 'session_expired'
      end

      # format.js { render :json => returnObj['status'].to_json }
      format.js { render :json => returnObj.to_json }
    end
  end

  def request_token
    respond_to do |format|
      returnObj = {}

      if current_user
        co = current_user.certificate_order_by_ref(params[:certificate_order_ref])
        co.update_attribute(:request_status, 'done')

        # Sending Notify to SysAdmin role's users.
        sys_admins = User.search_sys_admin.uniq
        sys_admins.each do |sys_admin|
          OrderNotifier.request_token_send(co, sys_admin, current_user).deliver
        end

        # Sending Notify to TeamAdmin role's users.
        team_account = current_user.ssl_account
        unless team_account.blank?
          team_admins = team_account.get_account_admins
          team_admins.each do |team_admin|
            OrderNotifier.request_token_send(co, team_admin, current_user).deliver
          end
        end

        returnObj['status'] = 'success'
      else
        returnObj['status'] = 'session_expired'
      end

      format.js { render :json => returnObj.to_json }
    end
  end

  def confirm
    co_token = CertificateOrderToken.find_by_token(params[:token])
    if co_token.user.blank? and co_token.certificate_order.get_download_cert_email==current_user.email
      co_token.update_column :user_id, current_user.id
    end

    if co_token
      if co_token.is_expired
        flash[:error] = "The page has expired or is no longer valid"
      elsif co_token.due_date < DateTime.now
        flash[:error] = "The page has expired or is no longer valid"
        co_token.update_attribute(:is_expired, true)
      elsif co_token.user != current_user or co_token.certificate_order.get_download_cert_email!=current_user.email
        flash[:error] = "Access to this page is denied. Please log in as the user assigned this token."
      else
        ssl_slug = co_token.certificate_order.ssl_account.acct_number || co_token.certificate_order.ssl_account.ssl_slug
        redirect_to generate_cert_certificate_order_path(ssl_slug, co_token.certificate_order.ref) and return
      end
    else
      flash[:error] = "Provided URL is incorrect."
    end
  end
end
