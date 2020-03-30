# == Schema Information
#
# Table name: funded_accounts
#
#  id             :integer          not null, primary key
#  card_declined  :text(65535)
#  cents          :integer          default("0")
#  currency       :string(255)
#  state          :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  ssl_account_id :integer
#
# Indexes
#
#  index_funded_accounts_on_ssl_account_id  (ssl_account_id)
#

class FundedAccount < ApplicationRecord
  using_access_control
  belongs_to :ssl_account

  money :amount, cents: :cents, currency: false

  validates_presence_of :ssl_account

  attr_accessor :funding_source, :order_type, :deduct_order, :target_amount, :discount_amount

  serialize :card_declined

  after_initialize do
    self.deduct_order ||= false if new_record?
  end

  NEW_CREDIT_CARD = 'new credit card'
  PAYPAL = 'paypal'

  def deduct_order?
    ['true', true].include? @deduct_order
  end

  def add_cents(cents)
    FundedAccount.update_counters id, cents: cents
  end

  def card_recently_declined?
    card_declined && card_declined[:declined_at] &&
      card_declined[:declined_at].is_a?(DateTime) &&
      card_declined[:declined_at] > 1.hour.ago
  end

  def delay_transaction
    return false unless card_recently_declined?

    if card_recently_declined?
      cards  = card_declined[:cards]
      max    = cards&.any? && cards.count >= 5 && cards.uniq.count == 1
      user   = User.unscoped.find card_declined[:user_id]
      update(card_declined: card_declined.merge(next_attempt: card_declined[:declined_at] + (max ? 1.minute : 30.seconds)))
      if max
        SystemAudit.create(
          owner: user,
          target: self,
          action: "Transaction declines have reached maximum limit of 5 attempts. #{card_declined[:controller]}",
          notes: "Card ending in ##{cards.last} was declined 5 times in the last hour. User #{user.login} from team #{ssl_account.get_team_name}."
        )
      end
    end
  end
end
