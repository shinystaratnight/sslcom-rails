class FundedAccountDecorator < Draper::Decorator
  delegate_all

  def available
    object.cents * 0.01
  end
end
