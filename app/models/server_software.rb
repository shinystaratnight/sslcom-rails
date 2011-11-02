class ServerSoftware < ActiveRecord::Base
  has_many :certificate_contents
  has_many :certificate_orders, through: :certificate_contents

  def self.listing
    all.map{|s|[s.id, s.title]}
  end
end
