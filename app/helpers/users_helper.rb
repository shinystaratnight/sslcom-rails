# frozen_string_literal: false

module UsersHelper
  def user_status(user)
    result =
      case user.status
      when /suspended/, /canceled/
        [Regexp.last_match(1), 'alert']
      end
    if result.blank?
      result = user.active? ? %w[activated good] : ['not activated',
                                                    'caution']
    end
    result
  end

  def user_role_names(user)
    user_roles = ''
    User.get_user_accounts_roles_names(user).each do |ssl|
      user_roles << "<strong>#{ssl.first}</strong>: #{ssl.second.join(', ')}<br />"
    end
    user_roles
  end

  def ssl_account_status(user, account)
    if user.ssl_accounts.include?(account)
      params = { ssl_account_id: account.id }
      ssl = user.ssl_account_users.where(params).first
      if ssl&.approved
        %w[approved good]
      else
        if user.user_declined_invite?(params)
          %w[declined caution]
        elsif user.approval_token_valid?(params.merge(skip_match: true))
          %w[sent caution]
        else
          ['token expired', 'caution']
        end
      end
    end
  end

  def team_index_permissions(user, team)
    permit = []
    roles  = user.role_symbols(team)
    unless roles.empty?
      roles.each do |role|
        case role
        when :users_manager
          permit << [:users]
        when :installer
          permit << %i[orders validations site_seals]
        when :validations
          permit << %i[validations site_seals]
        when :billing
          permit << %i[orders transactions billing_profiles]
        when :account_admin, :owner, :reseller
          permit << %i[users orders transactions validations site_seals billing_profiles]
        end
      end
    end
    permit.flatten.uniq.compact
  end

  def display_image_url(user)
    user.avatar.file.nil? ? 'https://via.placeholder.com/150' : user.avatar.url
  end
end
