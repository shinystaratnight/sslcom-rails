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
      ssl = user.ssl_account_users.where(ssl_account_id: account.id).first
      if ssl.approved
        ['approved', 'good']
      else
        if user.approval_token_valid?(ssl_account_id: account.id, skip_match: true)
          ['sent', 'caution']
        else
          ['token expired', 'caution']
        end
      end
    end  
  end
end
