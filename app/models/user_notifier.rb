class UserNotifier < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods
  default_url_options[:host] = Settings.actionmailer_host

  def activation_instructions(user)
    @account_activation_url = register_url(user.perishable_token)
    mail subject: "SSL.com user account activation instructions",
            from: Settings.from_email.activations,
              to: user.email
  end

  def activation_confirmation(user)
    @account_url = account_url
    @login = user.login
    mail subject: "SSL.com user account activated",
            from: Settings.from_email.activations,
              to: user.email
  end

  def password_reset_instructions(user)
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    mail  subject: "SSL.com user account password reset instructions",
             from: Settings.from_email.activations,
               to: user.email
  end

  def password_changed(user)
    mail subject: "SSL.com user account password changed",
           from:  Settings.from_email.activations,
             to:  user.email
  end

  def email_changed(user, email)
     @user=user
     mail  subject: "SSL.com user account email address changed",
              from: Settings.from_email.activations,
                to: email
  end

  def username_reminder(user)
     @login = user.login
     mail  subject: "SSL.com username reminder",
              from: Settings.from_email.activations,
                to: user.email
  end

  def signup_invitation(user, current_user, base_url, invited_teams)
    @user          = user
    @current_user  = current_user
    @ssl_account   = user.ssl_account
    @invited_teams = invited_teams
    @invite_url    = "#{base_url}register/#{@user.perishable_token}?invite=true"
    @login         = user.login
    mail subject: "#{@current_user.login} has invited you to join SSL.com",
            from: Settings.from_email.activations,
              to: user.email
  end

  def invite_to_account(invite_user, current_user, ssl_account_id)
    @invited_user = invite_user
    @current_user = current_user.is_a?(User) ? current_user : User.find(current_user)
    @ssl_account  = SslAccount.find ssl_account_id
    @approval_url = approve_account_invite_user_url(@invited_user)
    @approval_url << @invited_user.generate_approval_query(ssl_account_id: @ssl_account.id)
    @token_expire = @invited_user.ssl_account_users.find_by(ssl_account_id: @ssl_account.id).token_expires
    mail subject: "Invition to SSL.com team #{@ssl_account.get_team_name}",
            from: @current_user.email,
              to: @invited_user.email
  end

  def invite_to_account_notify_admin(invite_user, current_user, ssl_account_id)
    @invited_user = invite_user
    @current_user = current_user.is_a?(User) ? current_user : User.find(current_user)
    @ssl_account  = SslAccount.find ssl_account_id
    mail subject: "You have invited a user to your SSL.com team #{@ssl_account.get_team_name}",
            from: Settings.from_email.activations,
              to: @current_user.email
  end

  def removed_from_account(user, account, current_user)
    @remove_user  = user
    @current_user = current_user
    @ssl_account  = account
    mail subject: "You have been removed from SSL.com account",
            from: @current_user.email,
              to: @remove_user.email
  end

  def removed_from_account_notify_admin(user, account, current_user)
    @remove_user  = user
    @current_user = current_user
    @ssl_account  = account
    mail subject: "You have removed user from SSL.com account",
            from: Settings.from_email.activations,
              to: @current_user.email
  end

  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    setup_sender_info
    @subject     = "[#{Settings.community_name}] "
    @sent_on     = Time.now
    @body[:user] = user
  end

  def setup_sender_info
    @from       = "The #{Settings.community_name} Team <#{Settings.support_email}>"
    headers     "Reply-to" => "#{Settings.support_email}"
    @content_type = "text/plain"
  end

end
