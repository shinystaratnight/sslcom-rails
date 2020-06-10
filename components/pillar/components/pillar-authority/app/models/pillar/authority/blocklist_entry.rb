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
module Pillar
  module Authority
    class BlocklistEntry < ApplicationRecord
      has_many :blocklist_entry_exemptions, dependent: :destroy

      validates :pattern, presence: true, uniqueness: { case_sensitive: false }

      accepts_nested_attributes_for :blocklist_entry_exemptions, allow_destroy: true, reject_if: proc { |attr| attr['account_id'].blank? }

      def self.types
        [
          ["Blacklist", "Pillar::Authority::BlocklistEntryTypes::Blacklist"],
          ["HighRisk", "Pillar::Authority::BlocklistEntryTypes::Highrisk"]
        ]
      end

      def self.matches?(certificate_content, account_id = nil)
        certificate_content.certificate_names.reload
        
        offenses = []
        subject_hash = {}
        subject_dn = certificate_content&.subject_dn
        domains = certificate_content&.certificate_names.map(&:name)
        registrant = certificate_content&.registrant || certificate_content&.certificate_order&.locked_recipient

        subject = OpenSSL::X509::Name.parse(subject_dn)
        domains.delete(subject.try(:common_name))

        subject_hash = {
          common_name: subject.try(:common_name),
          organization: registrant&.company_name || subject.try(:organization),
          organization_unit: registrant&.department || subject.try(:organizational_unit),
          location: registrant&.city || subject.try(:locality),
          state: registrant&.state || subject.try(:state),
          country: registrant&.country || subject.try(:country),
          san: domains.join(",") || nil
        }

        subject_hash.each_with_index do |(key, value), index|
          if index == 0
            @query = BlocklistEntry.where("? REGEXP LOWER(pattern) AND `#{key}` = ?", value&.downcase, true)
          else
            @query = @query.or("? REGEXP LOWER(pattern) AND `#{key}` = ?",  value&.downcase, true)
          end      
        end

        puts "====> SUBJECT DN CHECK <===="
        puts "\tSubjectDN => #{subject_dn.inspect}"
        puts "\tDomains => #{domains.inspect}"
        puts "\tSubjectHash => #{subject_hash.inspect}"
        puts "\tQuery => #{@query.to_sql}"

        @query.all.each do |row|
          if account_id
            exempt = row.blocklist_entry_exemptions.where(account_id: account_id).exists?
          else
            exempt = false
          end

          unless exempt
            offense = {
              type: row.type,
              matches: build_match_array(subject_hash, row),
              blocklist_entry_id: row.id,
              blocklist_entry_pattern: row.pattern
            }

            offenses.push(offense)
          end
        end

        puts "\tOffenses => #{offenses.inspect}"
        offenses
      end

      private

      def self.build_match_array(subject_hash, row)
        matches = []

        subject_hash.each do |key, value|
          if row.send(key) === true && value&.downcase&.match(row.pattern.downcase)
            matches.push({ field: key, value: value })
          end
        end

        matches
      end
    end
  end
end
