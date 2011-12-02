class Unsubscribe < ActiveRecord::Base
  validates :email, presence: true, email: true, on: :create
  validates :specs, presence: true, on: :create
  validates :domain, presence: true, on: :create
  validates :ref, presence: true, on: :create

  before_validation do |un|
    un.ref ||='un-'+ActiveSupport::SecureRandom.hex(1)+Time.now.to_i.to_s(32)
  end
end
