class LockedRecipient < Contact
  belongs_to :certificate_order, class_name: 'CertificateOrder', foreign_key: :contactable_id, inverse_of: :locked_recipient
  validates :user_id, presence: true

  def self.create_for_co(co, target_assignee=nil)
    assignee = target_assignee.nil? ? co.assignee : User.find(target_assignee)
    locked_recipient = co.locked_recipient
    co.reload
    
    if assignee 
      iv = co.ssl_account.individual_validations.find_by(user_id: assignee.id)
      params = {
        first_name: iv ? iv.first_name : assignee.first_name,
        last_name: iv ? iv.last_name : assignee.last_name,
        email: assignee.email,
        user_id: assignee.id,
        contactable_type: co.class,
        contactable_id: co.id,
        parent_id: iv ? iv.id : nil,
        status: (iv ? Contact::statuses[iv.status] : Contact::statuses[:in_progress])
      }
      temp_lr = LockedRecipient.new(params)
      lr = temp_lr if locked_recipient.nil? && temp_lr.save
      

      if target_assignee && locked_recipient
        lr = locked_recipient.update(params)
        lr = co.locked_recipient
      end  

      if lr.persisted? && iv && iv.validation_histories.any?
        lr.validation_histories << iv.validation_histories
      end
    end
    lr
  end
end
