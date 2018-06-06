#!/usr/bin/env ruby
# 
# Update cents attribute based on the stored amount (old_amount) value
#
OrderTransaction.find_each do |ot|
  ot.update(cents: (ot.old_amount * 100)) unless ot.old_amount.blank?
end