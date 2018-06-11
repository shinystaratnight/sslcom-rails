module FundedAccountsHelper

  # do we show the billing info prompt?
  def initial_display?
    return {} unless current_user
    ssl = (@reprocess_ucc || @payable_invoice) ? @ssl_account : current_user.ssl_account
    ((ssl.billing_profiles(true).reject(&"expired?".to_sym).blank? && !current_page?(action: "allocate_funds")) ||
      @funded_account.try(:funding_source)==FundedAccount::NEW_CREDIT_CARD ||
      !@billing_profile.try(:errors).blank? || !flash.now[:error].blank?) ?
      {} : {:class => 'hidden'}
  end

  def initial_reseller_deposit?
    current_user.ssl_account.has_role?('new_reseller') && (
          current_user.ssl_account.reseller.enter_billing_information? ||
          current_user.ssl_account.reseller.select_tier?)
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

  def destroy_credit_card_link(item, options={})
    link_to 'delete', billing_profile_path(id: item), :remote=>true, 
      :class=>'delete_profile', :method => :delete, id: options[:id],
      :confirm => "Are you sure you want to delete the credit card profile for #{item.masked_card_number}? This action cannot be undone."
  end

  def apply_or_free
    is_order_free? ? create_free_ssl_path : apply_funds_path
  end
end
