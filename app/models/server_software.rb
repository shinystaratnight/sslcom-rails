# == Schema Information
#
# Table name: server_softwares
#
#  id          :integer          not null, primary key
#  support_url :string(255)
#  title       :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#

class ServerSoftware < ApplicationRecord
  has_many :certificate_contents
  has_many :certificate_orders, through: :certificate_contents

  OTHER="1"

  def self.listing
    all.map{|s|[s.id, s.title]}
  end
end
