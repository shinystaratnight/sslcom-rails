class Unsubscribe < ApplicationRecord
  validates :email, presence: true, email: true, :uniqueness=>
      {:scope=>[:domain]}, on: :create
  validates :specs, presence: true, on: :create
  validates :domain, presence: true, on: :create
  validates :ref, presence: true, on: :create

  ALL="all"
  ONLY="only"

  before_validation do |un|
    un.ref ||='un-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32)
  end
end
