# frozen_string_literal: true

# The decision or current status on a validation rule requirement on a given validation material (document)

class ValidationRuling < ApplicationRecord
  include Workflow

  belongs_to :validation_rulable, polymorphic: true
  belongs_to :validation_rule
  acts_as_notable

  validates_uniqueness_of :validation_rule_id, scope: %i[validation_rulable_id validation_rulable_type]

  REVIEWING = 'reviewing documents'
  WAITING_FOR_DOCS = 'waiting for documents'
  INSUFFICIENT = 'insufficient, more documents needed'
  APPROVED = 'approved'
  UNAPPROVED = 'unapproved'

  # admin actions
  UNAPPROVE = 'unapprove'
  APPROVE = 'approve'
  MORE_REQUIRED = 'more required'
  DECLINED_ACTIONS = [UNAPPROVE, MORE_REQUIRED].freeze

  APPROVED_CLASS = 'validation_approved'
  WAITING_CLASS = 'validation_waiting'
  ATTENTION_CLASS = 'validation_attention'

  NEW_STATUS = 'processing'
  NEW_EV_STATUS = 'validation documents required'
  MORE_REQUIRED_STATUS = 'additional documentation needed'
  PENDING_STATUS = 'performing validations'
  PENDING_EXPRESS_STATUS = 'reviewing organization validation'
  APPROVED_STATUS = 'validation has been satisfied'
  UNAPPROVED_STATUS = 'validation documents have been uploaded but did not meet minimum requirements'

  DCV_WAIT_STATUS = 'waiting on domain control response'

  EXPAND = '. click for details'

  workflow do
    state :new do
      event :unapprove, transitions_to: :unapproved
      event :approve, transitions_to: :approved
      event :require_more, transitions_to: :more_required
      event :validation_submitted, transitions_to: :pending
      event :approve_through_override, transitions_to: :approved_through_override
    end

    state :pending do
      event :approve, transitions_to: :approved
      event :unapprove, transitions_to: :unapproved
      event :require_more, transitions_to: :more_required

      on_entry do
        vr = validation_rulable
        vr.pend! if vr.is_a?(Validation) && vr.approved?
      end
    end

    state :approved do
      event :unapprove, transitions_to: :unapproved
      event :validation_submitted, transitions_to: :pending
      event :require_more, transitions_to: :more_required
      event :pend, transitions_to: :pending

      on_entry do
        vr = validation_rulable
        vr.approve! if vr.is_a?(Validation) && !vr.approved? && vr.validation_rulings.all{ |v| v.approved? }
      end
    end

    state :approved_through_override do
      event :unapprove, transitions_to: :unapproved

      on_entry do
        vr = validation_rulable
        vr.approve! if vr.is_a?(Validation) && !vr.approved? && vr.validation_rulings.all{ |v| v.approved? }
      end
    end

    state :more_required do
      event :approve, transitions_to: :approved
      event :unapprove, transitions_to: :unapproved
      event :pend, transitions_to: :pending
    end

    state :unapproved do
      event :approve, transitions_to: :approved
      event :validation_submitted, transitions_to: :pending
      event :require_more, transitions_to: :more_required
      event :pend, transitions_to: :pending
    end

    state :not_applicable
    state :certificate
  end
end
