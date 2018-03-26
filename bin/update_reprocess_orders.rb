#!/usr/bin/env ruby
# 
# Update existing reprocess orders "description" and "type"
#
Order.where{description =~ "%Reprocess UCC Order%"}.each do |order|
  order.update(
    type: 'ReprocessCertificateOrder',
    description: 'Domains Adjustment'
  )
end