class DuplicateV2User < ActiveRecord::Base
  belongs_to  :user
  has_many    :legacy_v2_user_mappings, :as=>:user_mappable

  def self.find_and_notify(params)
    if dup = find_by_login(params[:login]) || find_by_email(params[:email])
      DuplicateV2UserMailer.duplicate_found(dup).deliver!
    else
      false
    end
  end

  def self.find_mismatch
    [].tap do |mm|
      all.select do |d|
        unless d.user.legacy_v2_user_mappings.blank?
          mapping=d.user.legacy_v2_user_mappings.last.customer
          mm << mapping if mapping.login!=d.user.login || mapping.email!=d.email
        end
      end
    end
  end

  def self.mismatched_attributes
    [].tap do |mm|
      all.select do |d|
        unless d.user.legacy_v2_user_mappings.blank?
          mapping=d.user.legacy_v2_user_mappings.last.customer
          mm << [[d.login, d.email],[mapping.login, mapping.email]] if mapping.login!=d.user.login || mapping.email!=d.email
        end
      end
    end
  end

  def self.sync_mismatched_attributes
   all.select do |d|
      unless d.user.legacy_v2_user_mappings.blank?
        mapping=d.user.legacy_v2_user_mappings.last.customer
        d.update_attributes(login: mapping.login, email: mapping.email) if mapping.login!=d.user.login || mapping.email!=d.email
      end
    end
  end
end
