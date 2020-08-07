class DuplicateV2User < ApplicationRecord
  belongs_to  :user
  has_many    :legacy_v2_user_mappings, :as=>:user_mappable

  IGNORE = %w(leo@ssl.com rabbit sy_adm1n buttysquirrel)

  def source_obj
    m = V2MigrationProgress.find_by_migratable(self)
    m.last.source_obj unless m.blank?
  end

  def v2_migration_progress
    m = V2MigrationProgress.find_by_migratable(self, :all)
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


  # this function will make accounts with duplicates to use the latest
  # login with the most "updated_at" changed field the primary login
  def self.make_latest_login_primary
    #add each user to a hash
    users = DuplicateV2User.all.map(&:user).uniq
    swap=[]
    users.each do |user|
      next if IGNORE.include? user.login
      recent_dup=user.duplicate_v2_users.sort{|a,b|a.updated_at<=>b.updated_at}.last
      if recent_dup.updated_at.to_date > user.updated_at.to_date
        swap << user
        p "#{user.model_and_id} (#{user.login}) being swapped with #{recent_dup.login}"
        recent_dup.swap_with(user)
      end
    end
    swap
  end

  #swap attributes and v2_migration_progress
  def swap_with(user)
    if (V2MigrationProgress.find_non_mapped(DuplicateV2User)+
        V2MigrationProgress.find_multiple_mapped(DuplicateV2User)).include? self
      p "DuplicateV2User #{model_and_id} (#{login}) has no or multiple v2_migration_progresses"
    elsif (V2MigrationProgress.find_non_mapped(User)+
        V2MigrationProgress.find_multiple_mapped(User)).include? user
      p "User #{user.model_and_id} (#{user.login}) has no or multiple v2_migration_progresses"
    else
      #swap user<->dup attrs
      l,p,c,u=user.login, user.crypted_password, user.created_at, user.updated_at
      so=self.source_obj
      user.update_attributes(login: self.login,
                              crypted_password: self.password,
                              first_name: so.FirstName,
                              last_name: so.LastName,
                              created_at: self.created_at,
                              updated_at: self.updated_at)
      self.update_attributes(login: l,
                              password: p,
                              created_at: c,
                              updated_at: u)
      #swap v2_migration_progress
      dup=user.v2_migration_progresses.last
      p "swapping v2_migration_progresses for #{user.model_and_id} and #{dup.model_and_id}"
      ump=dup
      vmp=v2_migration_progress.last
      mtype, mid, mstable, msid=ump.migratable_type, ump.migratable_id, ump.source_table_name, ump.source_id
      ump.update_attributes migratable_type: vmp.migratable_type,
                            migratable_id: vmp.migratable_id,
                            source_table_name: vmp.source_table_name,
                            source_id: vmp.source_id
      vmp.update_attributes migratable_type: mtype,
                            migratable_id: mid,
                            source_table_name: mstable,
                            source_id: msid
      #swap legacy_v2_user_mappings
      if(!user.legacy_v2_user_mappings.empty? && !legacy_v2_user_mappings.empty?)
        p "swapping legacy_v2_users for #{user.model_and_id} and #{dup.model_and_id}"
        ulms=user.legacy_v2_user_mappings
        dlms=legacy_v2_user_mappings
        ulms.each do |ulm|
          p "assigning #{ulm.model_and_id} to #{dup.model_and_id}"
          ulm.user_mappable=dup
          ulm.save
        end
        dlms.each do |dlm|
          p "assigning #{dlm.model_and_id} to #{user.model_and_id}"
          dlm.user_mappable=user
          dlm.save
        end
      end
    end
  end
end
