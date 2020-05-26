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
FactoryBot.define do
  factory :authority_blocklist_entry_exemption, class: 'Pillar::Authority::BlocklistEntryExemption' do
    blocklist_id { 1 }
    account_id { 1 }
  end
end
