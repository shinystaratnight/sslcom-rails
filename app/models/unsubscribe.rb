# == Schema Information
#
# Table name: unsubscribes
#
#  id         :integer          not null, primary key
#  domain     :text(65535)
#  email      :text(65535)
#  enforce    :boolean
#  ref        :text(65535)
#  specs      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

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
