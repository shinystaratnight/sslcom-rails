



class Seller
  cattr_accessor :default_gateway
  attr_accessor :gateway
  
  def initialize(attributes={})
    self.gateway = attributes[:gateway]
  end
  
end