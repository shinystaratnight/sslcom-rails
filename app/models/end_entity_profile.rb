# == Schema Information
#
# Table name: cas
#
#  id              :integer          not null, primary key
#  admin_host      :string(255)
#  algorithm       :string(255)
#  ca_name         :string(255)
#  caa_issuers     :string(255)
#  client_cert     :string(255)
#  client_key      :string(255)
#  client_password :string(255)
#  description     :string(255)
#  ekus            :string(255)
#  end_entity      :string(255)
#  friendly_name   :string(255)
#  host            :string(255)
#  profile_name    :string(255)
#  ref             :string(255)
#  size            :integer
#  type            :string(255)
#
# Indexes
#
#  index_cas_on_id_and_type  (id,type)
#

class EndEntityProfile < Ca

end
