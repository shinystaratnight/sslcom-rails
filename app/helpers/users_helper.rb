module UsersHelper
  def user_status(user)
    result =
      case user.status
      when /suspended/, /canceled/
        [$1, 'alert']
      end
    if result.blank?
      result = (user.active?) ? ["activated", "good"] : ["not activated",
        "caution"]
    end
    result
  end

  def ssl_account_status(user, account)
    if user.ssl_accounts.include?(account)
      params = {ssl_account_id: account.id}
      ssl = user.ssl_account_users.where(params).first
      if ssl.approved
        ['approved', 'good']
      else
        if user.user_declined_invite?(params)
          ['declined', 'caution']
        elsif user.approval_token_valid?(params.merge(skip_match: true))
          ['sent', 'caution']
        else
          ['token expired', 'caution']
        end
      end
    end  
  end
end
