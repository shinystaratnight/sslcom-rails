#!/usr/bin/env ruby
# 
# rails r bin/refactor_shadow_certificates.rb
# 
# Create ShadowSignedCertificate based on if ca_id is shadow CA
#
SignedCertificate.where{ca_id == 1}.find_each do |sc|
  sc.update_column :type, "ShadowSignedCertificate"
end