Money.class_eval do
  def ==(other_money)
    return false unless defined? other_money.cents
    cents == other_money.cents && bank.same_currency?(currency, other_money.currency)
  end
end

