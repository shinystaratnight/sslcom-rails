# == Schema Information
#
# Table name: verifications
#
#  id          :integer          not null, primary key
#  call_number :string(255)
#  call_prefix :string(255)
#  email       :string(255)
#  sms_number  :string(255)
#  sms_prefix  :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#
# Indexes
#
#  fk_verifications_user_id  (user_id)
#
# Foreign Keys
#
#  fk_verifications_user_id  (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
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
