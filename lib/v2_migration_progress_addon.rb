module V2MigrationProgressAddon
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    define_method :v2_migration_progresses do
      V2MigrationProgress.where(:migratable_type =~ base_class.to_s)
    end

    define_method :v2_migration_sources do
      vmp=v2_migration_progresses
      table_names = vmp.map(&:source_table_name).uniq
      s=[]
      table_names.each do |t|
        ids=vmp.where{source_table_name =~ t}.map(&:source_id)
        o=OldSite::Base.descendants.find{|c|
          c.table_name==t}
        s+=o.where{o.primary_key.to_sym >> ids}
      end
      s
    end
  end

  def v2_migration_progresses
    V2MigrationProgress.find_by_migratable(self, :all)
  end

  def v2_migration_sources
    vmp=v2_migration_progresses
    vmp.map(&:source_obj) unless vmp.blank?
  end
end
