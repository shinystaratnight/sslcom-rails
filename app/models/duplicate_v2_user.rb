class DuplicateV2User < ActiveRecord::Base
  belongs_to  :user
  has_many    :legacy_v2_user_mappings, :as=>:user_mappable

  def source_obj
    m = V2MigrationProgress.find_by_migratable(self)
    m.source_obj unless m.blank?
  end

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
        so = d.source_obj
        unless so.blank?
          mm << so if (so.login!=d.login || so.email!=d.email)
        end
      end
    end
  end

  def self.mismatched_attributes
    [].tap do |mm|
      all.each do |d|
        so = d.source_obj
        unless so.blank?
          mm << [[d.login, d.email],[so.login, so.email]] if (so.login!=d.login || so.email!=d.email)
        end
      end
    end
  end

  def self.sync_mismatched_attributes
    [].tap do |mm|
      all.each do |d|
        so = d.source_obj
        unless so.blank?
         d.update_attributes(login: so.login, email: so.email) if (so.login!=d.login || so.email!=d.email)
        end
      end
    end
  end

  #temporary function to assist in migration
  if MIGRATING_FROM_LEGACY
    def update_record_without_timestamping
      class << self
        def record_timestamps; false; end
      end

      save(false)

      class << self
        def record_timestamps; super ; end
      end
    end
  end
end
