Factory.define :registrant do |r|
  r.association :contactable, :factory=>:certificate_content
end

Factory.define :certificate_content do |cc|
  cc.association :certificate_order
end

Factory.define :certificate_order do |co|
  co.has_csr false
  co.association :ssl_account
  co.association :sub_itemable, :factory=>:sub_order_item
end

Factory.define  :sub_order_item do |soi|
  soi.association :product_variant_item
end

Factory.define  :funded_account do |fa|
  fa.association :ssl_account
end

Factory.define  :product_variant_item do |pvi|
  pvi.association :sub_itemable, :factory=>:certificate_order
end

Factory.define :reminder_trigger do |rt|
  rt.sequence(:id){|i|i}
end

Factory.define :ssl_account do |sa|
  sa.preferred_reminder_notice_destinations '0'
end


