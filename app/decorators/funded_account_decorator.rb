class FundedAccountDecorator < ApplicationDecorator
  delegate_all

  def available
    object.amount.format
  end
end
