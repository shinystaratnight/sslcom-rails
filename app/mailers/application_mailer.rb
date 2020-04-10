class ApplicationMailer < ActionMailer::Base
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ApplicationHelper
  include SettingsHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  helper ApplicationHelper
  helper SettingsHelper

  default from: 'from@example.com'
  layout 'mailer'
end
