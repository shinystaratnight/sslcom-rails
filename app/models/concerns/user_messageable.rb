module UserMessageable
  extend ActiveSupport::Concern
  
  class_methods do
    
  end
  
  def mailboxer_name
    str = "#{self.first_name} #{self.last_name}"
    str = self.email if str.strip.empty?
    str
  end

  def mailboxer_email(object)
    self.email
  end

  def mailboxer_recipients
    list = get_all_approved_accounts
    result = []
    if list.any?
      result = User.joins(:ssl_account_users)
        .where(ssl_account_users: {ssl_account_id: list.map(&:id)})
        .uniq.map{|u| u.email}
    end
    result
  end

  def mailboxer_fetch_recipients(conversation)
    conversation.receipts.reject{ |p| p.receiver == self }
      .first.receiver.try(:email)
  end
end
