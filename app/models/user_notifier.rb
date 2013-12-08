class UserNotifier < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods
  default_url_options[:host] = Settings.actionmailer_host

  def activation_instructions(user)
    @account_activation_url = register_url(user.perishable_token)
    mail subject:       "SSL.com user account activation instructions",
            from:          Settings.from_email.activations,
            to:    user.email
  end

  def activation_confirmation(user)
    @account_url = account_url
    @login = user.login
    mail subject:       "SSL.com user account activated",
            from:          Settings.from_email.activations,
            to:    user.email
  end

  def password_reset_instructions(user)
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    mail  subject:      "SSL.com user account password reset instructions",
             from:         Settings.from_email.activations,
             to:   user.email
  end

  def password_changed(user)
    mail subject:       "SSL.com user account password changed",
           from:          Settings.from_email.activations,
           to:    user.email
  end

  def email_changed(user, email)
     @user=user
     mail  subject:      "SSL.com user account email address changed",
              from:         Settings.from_email.activations,
              to:   email
  end

  def username_reminder(user)
     @login = user.login
     mail  subject:       "SSL.com username reminder",
              from:          Settings.from_email.activations,
              to:    user.email
  end

  def signup_invitation(email, user, message)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "#{user.login} would like you to join #{Settings.community_name}!"
    @sent_on     = Time.now
    @body[:user] = user
    @body[:url]  = signup_by_id_url(user, user.invite_code)
    @body[:message] = message
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
