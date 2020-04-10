module SettingsHelper
  def community_name
    Settings.community_name
  end

  def community_domain
    Settings.community_domain
  end

  def portal_domain
    Settings.portal_domain
  end

  def support_email
    Settings.support_email
  end

  def orders_from_email
    Settings.from_email.orders
  end

  def no_reply_email
    Settings.from_email.no_reply
  end

  def activations_from_email
    Settings.from_email.activations
  end

  def notify_address
    Settings.notify_address
  end
end
