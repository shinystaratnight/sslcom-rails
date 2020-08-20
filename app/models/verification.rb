class Verification < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true
  # Validate existence of prefix when phone exists
  validates :call_prefix, presence: true, if: -> { call_number.present? }
  validates :sms_prefix, presence: true, if: -> { sms_number.present? }
  validate :minimum_one_method

  def minimum_one_method
    errors.add(:base, 'at least one verification method required') if email.nil? && call_number.nil? && sms_number.nil?
  end
end
