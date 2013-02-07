class Discount < ActiveRecord::Base
  belongs_to  :discountable, polymorphic: true
  APPLY_AS = [:percentage, :absolute]

end
