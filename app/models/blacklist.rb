# == Schema Information
#
# Table name: blocklists
#
#  id          :integer          not null, primary key
#  description :string(255)
#  domain      :string(255)
#  notes       :text(65535)
#  reason      :string(255)
#  status      :string(255)
#  type        :string(255)
#  validation  :integer
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_blocklists_on_id_and_type  (id,type)
#

class Blacklist < Blocklist
end
