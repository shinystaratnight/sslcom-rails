class UserNotifier < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods
  ActionMailer::Base.default_url_options[:host] = APP_URL.sub('http://', '')

  def activation_instructions(user)
    subject       "SSL.com Activation Instructions"
    from          Settings.from_email.activations
    recipients    user.email
    sent_on       Time.now
    body          :account_activation_url => register_url(user.perishable_token)
  end

  def activation_confirmation(user)
    subject       "SSL.com Activation Complete"
    from          Settings.from_email.activations
    recipients    user.email
    sent_on       Time.now
    body          :root_url => root_url
  end

 def password_reset_instructions(user)  
   subject       "SSL.com Password Reset Instructions"  
   from          Settings.from_email.activations
   recipients    user.email  
   sent_on       Time.now  
   body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)  
 end

 def password_changed(user)
   subject       "SSL.com Account Password Changed"
   from          Settings.from_email.activations
   recipients    user.email
   sent_on       Time.now
 end

 def email_changed(user, email)
   subject       "SSL.com Account Email Address Changed"
   from          Settings.from_email.activations
   recipients    email
   sent_on       Time.now
   body          :user=>user
 end

 def username_reminder(user)
   subject       "SSL.com Username Reminder"
   from          Settings.from_email.activations
   recipients    user.email
   sent_on       Time.now
   body          :login => user.login
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
