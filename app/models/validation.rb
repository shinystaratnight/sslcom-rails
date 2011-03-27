class Validation < ActiveRecord::Base
  has_many    :certificate_orders
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
    end

    state :pending do
      event :approve, :transitions_to => :approved
      event :unapprove, :transitions_to => :unapproved
    end

    state :approved do
      event :unapprove, :transitions_to => :unapproved
      event :validation_submitted, :transitions_to => :pending
    end

    state :approved_through_override do
      event :unapprove, :transitions_to => :unapproved
    end

    state :unapproved do
      event :approve, :transitions_to => :approved
      event :validation_submitted, :transitions_to => :pending
    end

    state :not_applicable
  end

  NONE_SELECTED="None"

  def last_document_uploaded_on
    return "" if validation_histories.empty?
    validation_histories.last.created_at.strftime("%b %d, %Y")
  end

  def modify_validation_rulings(validation_history)
    validation_rulings.each{|vr| vr.validation_submitted! if vr.new?}
  end
end
