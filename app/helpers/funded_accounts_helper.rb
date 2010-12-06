module FundedAccountsHelper

  def initial_display?
    return {} unless current_user
    current_user.ssl_account.billing_profiles(true).blank? ||
      @funded_account.try(:funding_source)==FundedAccount::NEW_CREDIT_CARD ||
      !@billing_profile.try(:errors).blank? ?
      {} : {:class => 'hidden'}
  end

  def initial_reseller_deposit?
    current_user.ssl_account.has_role?('new_reseller') &&
          current_user.ssl_account.reseller.enter_billing_information?
  end

  def load_amounts(deduct_order)
    max_load_amount = Money.new(1000000)
    min_load_amount = Money.new(100000)
    step_amount = Money.new(300000)
    order_amount = current_order.amount or step_amount
    if order_amount.cents > max_load_amount.cents
      [[order_amount.format(:with_currency), order_amount.cents.to_s]]
    else
      skip = (deduct_order)? order_amount.cents / step_amount.cents : 0
      brackets = (max_load_amount.cents / step_amount.cents).enum_for(:times).collect{|x|
        bracket_amount = Money.new((x+1)*(step_amount.cents))
        [bracket_amount.format(:with_currency=>true), bracket_amount.to_s]}
      while skip > 0
        brackets.shift
        skip-=1
      end
      brackets.find_all{|x|x[1].to_f >= min_load_amount.to_s.to_f}
    end
  end

  def funded_account_balance(with_currency=nil)
    account = current_user.ssl_account.funded_account(true)
    if with_currency == :with_currency
      (account.nil? or account.amount.to_s == "0.00") ?
        "$0.00 USD" : account.amount.format(:with_currency => true)
    else
      (account.nil?) ? "0.00" : account.amount
    end
  end

  def destroy_credit_card_link(item)
    link_to_remote 'Delete', :url => billing_profile_path(item), 
      :method => :delete, :confirm => "Are you sure you want to delete the credit card profile for #{item.masked_card_number}? This action cannot be undone.",
      :complete => visual_effect(:fade, item.model_and_id, :duration => 0.2)+"jQuery.last_delete_clicked();",
        :html=>{:class => 'delete_billing_profile'}
  end
end
