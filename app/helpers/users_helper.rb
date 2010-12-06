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
end
