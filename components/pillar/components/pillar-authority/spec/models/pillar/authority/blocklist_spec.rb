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
require 'rails_helper'

module Pillar
  module Authority
    RSpec.describe BlocklistEntry, type: :model do
      describe "associations" do
        let(:authority_blocklist_entry) { build(:authority_blocklist_entry) }

        it "has many blocklist_exemptions" do
          expect(authority_blocklist_entry).to have_many(:blocklist_entry_exemptions)
        end
      end

      describe "validations" do
        let(:authority_blocklist_entry) { build(:authority_blocklist_entry) }

        it "requires a pattern" do
          expect(authority_blocklist_entry).to validate_presence_of(:pattern)
        end

        it "requires a unique pattern" do
          expect(authority_blocklist_entry).to validate_uniqueness_of(:pattern).case_insensitive
        end
      end

      describe ".matches?" do
        before(:all) do
          authority_blocklist_entry = create(:authority_blocklist_entry, pattern: '.*?\.example\.com', common_name: true)
          authority_blocklist_entry.blocklist_entry_exemptions.create(account_id: 99)
          create(:authority_blocklist_entry, pattern: '^example\.com', common_name: true)
          create(:authority_blocklist_entry, pattern: 'Demo', organization: true)
          create(:authority_blocklist_entry, pattern: 'IT', organization_unit: true)
          create(:authority_blocklist_entry, pattern: 'Houston', location: true)
          create(:authority_blocklist_entry, pattern: 'Texas', state: true)
          create(:authority_blocklist_entry, pattern: 'US', country: true)
        end

        context "no matches found" do
          it "returns an empty array" do
            subject = build(:certificate_subject, common_name: 'www.verifieddomain.com')
            expect(BlocklistEntry.matches?(subject)).to eq([])
          end
        end

        describe "matches are found but account_id is exempt" do
          it "returns an empty array" do
            subject = build(:certificate_subject, common_name: 'www.example.com')
            expect(BlocklistEntry.matches?(subject, 99).length).to eq(0)
          end
        end

        describe "matches for common_name - subdomain present are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, common_name: 'www.example.com')
            expect(BlocklistEntry.matches?(subject).length).to eq(1)
          end
        end


        context "matches for common_name - subdomain not present are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, common_name: 'example.com')
            expect(BlocklistEntry.matches?(subject).length).to eq(1)
          end
        end

        context "matches for organization are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, organization: 'Demo')
            expect(BlocklistEntry.matches?(subject).length).to eq(1)
          end
        end

        context "matches for organization_unit are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, organization_unit: 'IT')
            expect(BlocklistEntry.matches?(subject).length).to eq(1)
          end
        end

        context "matches for location are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, locality: 'Houston')
            expect(BlocklistEntry.matches?(subject).length).to eq(1)
          end
        end

        context "matches for state are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, state: 'Texas')
            expect(BlocklistEntry.matches?(subject).length).to eq(1)
          end
        end

        context "matches for country are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, country: 'US')
            expect(BlocklistEntry.matches?(subject).length).to eq(1)
          end
        end

        context "matches for multiple items are found" do
          it "returns an array containing matches" do
            subject = build(:certificate_subject, common_name: "www.example.com", country: 'US')
            expect(BlocklistEntry.matches?(subject).length).to eq(2)
          end
        end

        context "matches for san are found" do
          it "returns an array containing matches" do
            # pending
          end
        end
      end
    end
  end
end
