class RegisteredAgent < ActiveRecord::Base
  belongs_to  :ssl_account
  belongs_to  :requester, :class_name => 'User'
  belongs_to  :approver, :class_name => 'User'
  has_many  :managed_certificates

  before_create do |ra|
    ra.ref = 'sm-' + SecureRandom.hex(1) + Time.now.to_i.to_s(32)
  end

  def to_param
    ref
  end
end