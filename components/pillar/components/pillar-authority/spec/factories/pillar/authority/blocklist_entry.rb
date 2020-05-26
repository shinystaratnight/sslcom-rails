# == Schema Information
#
# Table name: embark_authority_blocklists
#
#  id                :bigint           not null, primary key
#  common_name       :boolean
#  country           :boolean
#  description       :text(65535)
#  location          :boolean
#  organization      :boolean
#  organization_unit :boolean
#  pattern           :string(255)
#  state             :boolean
#  type              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :authority_blocklist_entry, class: 'Pillar::Authority::BlocklistEntry' do
    pattern { "" }
    description { "description text" }
    type { "" }
    common_name { false }
    organization { false }
    organization_unit { false }
    location { false }
    state { false }
    country { false }
  end
end
