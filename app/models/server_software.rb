class ServerSoftware < ApplicationRecord
  has_many :certificate_contents
  has_many :certificate_orders, through: :certificate_contents

  OTHER="1"

  def self.listing
    all.map{|s|[s.id, s.title]}
  end
end
