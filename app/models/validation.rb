# == Schema Information
#
# Table name: validations
#
#  id             :integer          not null, primary key
#  address1       :string(255)
#  address2       :string(255)
#  city           :string(255)
#  contact_email  :string(255)
#  contact_phone  :string(255)
#  country        :string(255)
#  domain         :string(255)
#  email          :string(255)
#  first_name     :string(255)
#  label          :string(255)
#  last_name      :string(255)
#  notes          :string(255)
#  organization   :string(255)
#  phone          :string(255)
#  postal_code    :string(255)
#  state          :string(255)
#  tax_number     :string(255)
#  website        :string(255)
#  workflow_state :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

class Validation < ApplicationRecord
  has_many    :certificate_orders, -> { unscope(where: [:workflow_state, :is_expired]) }
  has_many    :ssl_accounts, through: :certificate_orders
  has_many    :users, through: :ssl_accounts
  has_many    :validation_rulings, :as=>:validation_rulable
  has_many    :validation_rules, :through => :validation_rulings
  has_many    :validation_history_validations
  has_many    :validation_histories, :through=>
    :validation_history_validations, :after_add=>:modify_validation_rulings do
    def applied_to(validation_rule)
      all.find_all{|vh|vh.validation_rules.include? validation_rule}
    end
  end

  include Workflow
  workflow do
    state :new do
      event :validation_submitted, :transitions_to => :pending
      event :approve_through_override, :transitions_to =>
        :approved_through_override
      event :approve, transitions_to: :approved
    end

    state :pending do
      event :approve, :transitions_to => :approved
      event :unapprove, :transitions_to => :unapproved
    end

    state :approved do
      event :unapprove, :transitions_to => :unapproved
      event :validation_submitted, :transitions_to => :pending
      event :pend, :transitions_to => :pending

      on_entry do
        self.validation_rulings.each {|v|v.approve! unless v.approved?}
      end
    end

    state :approved_through_override do
      event :unapprove, :transitions_to => :unapproved

      on_entry do
        self.validation_rulings.each {|v|v.approve! unless v.approved?}
      end
    end

    state :unapproved do
      event :approve, :transitions_to => :approved
      event :validation_submitted, :transitions_to => :pending
    end

    state :not_applicable
  end

  NONE_SELECTED="None"
  COMODO_EMAIL_LOOKUP_THRESHHOLD=20 #the number of domains before we switch to manually generating validation addresses to reduce latency

  def last_document_uploaded_on
    return "" if validation_histories.empty?
    validation_histories.last.created_at.strftime("%b %d, %Y")
  end

  def modify_validation_rulings(validation_history)
    validation_rulings.each{|vr| vr.validation_submitted! if vr.new?}
  end
end
