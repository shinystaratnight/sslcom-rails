# == Schema Information
#
# Table name: blocklists
#
#  id                 :integer          not null, primary key
#  common_name        :boolean
#  country            :boolean
#  description        :text(65535)
#  exempt             :text(65535)
#  label              :string(255)
#  location           :boolean
#  notes              :text(65535)
#  organization       :boolean
#  organization_unit  :boolean
#  pattern            :string(255)
#  regular_expression :boolean
#  san                :boolean
#  state              :boolean
#  type               :string(255)
#

class Blacklist < Blocklist
end
