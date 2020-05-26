# == Schema Information
#
# Table name: embark_authority_blocklist_exemptions
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  blocklist_id :integer
#
module Pillar
  module Authority
    class BlocklistEntryExemption < ApplicationRecord
      belongs_to :blocklist_entry
    end
  end
end
