class FundedAccountDecorator < ApplicationDecorator
  delegate_all

  def available
    object.cents * 0.01
  end
end
