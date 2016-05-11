
class LineItem < ActiveRecord::Base
  belongs_to :order
  belongs_to :sellable, :polymorphic => true
  
  money :amount
  
  # set #amount when adding sellable.  This method is aliased to <tt>sellable=</tt>.
  def sellable_with_price=(sellable)
    self.amount = sellable && sellable.price ? sellable.price : 0
    self.sellable_without_price = sellable
  end
  alias_method_chain :sellable=, :price
  
end
