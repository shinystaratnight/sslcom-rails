# == Schema Information
#
# Table name: v2_migration_progresses
#
#  id                :integer          not null, primary key
#  migratable_type   :string(255)
#  migrated_at       :datetime
#  source_table_name :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  migratable_id     :integer
#  source_id         :integer
#
# Indexes
#
#  index_v2_migration_progresses_on_migratable_id  (migratable_id)
#  index_v2_migration_progresses_on_source_id      (source_id)
#

class V2MigrationProgress < ApplicationRecord
  belongs_to  :migratable, :polymorphic=>true
  validates_uniqueness_of :source_id, :scope=>:source_table_name

  def self.find_by_source(obj)
    find_by_old_object(obj)
  end

  #Finds the legacy object based on the transitory object
  def self.find_by_old_object(obj)
    pk=obj.class.primary_key
    self.find_by_source_table_name_and_source_id(obj.class.table_name,
      obj.send(pk))
  end

  def self.find_non_mapped(klass)
    joins("RIGHT JOIN `#{klass.table_name}` ON `#{klass.table_name}`.`id` =
      `v2_migration_progresses`.`migratable_id` AND `v2_migration_progresses`.`migratable_type` = '#{klass}'").where{migratable_id==nil}
    # klass.where{id.not_in(mapped.select{migratable_id})}
  end

  def self.find_multiple_mapped(klass)
    joins("INNER JOIN `#{klass.table_name}` ON `#{klass.table_name}`.`id` =
      `v2_migration_progresses`.`migratable_id` AND `v2_migration_progresses`.`migratable_type` = '#{klass}'").
        group(:migratable_id).having("count(migratable_id)>1")
  end

  def self.find_by_migratable(migratable, which=:first)
    where(:migratable_type=>migratable.class.to_s, :migratable_id=>migratable.id)
  end

  def self.find_by_migratable_and_source_table_name(
      migratable, source_table_name, which=:first)
    find(which) do |v|
      v.migratable_type==migratable.class.to_s &&
      v.migratable_id==migratable.id &&
      v.source_table_name==source_table_name
    end
  end

  def self.remove_legacy_orphans(legacy)
    #l_ids=all_ids legacy
    #vs_ids=select(:source_id).where(:source_table_name.eq => legacy.table_name).map(&:source_id)
    #if vs_ids.count > l_ids.count
    #  diff = vs_ids - l_ids
    #  where(:source_id + diff).delete_all
    #else
    #  0
    #end
    options={class: legacy, class_name: legacy.table_name, id: :source_id}
    remove_orphans options
  end

  def self.remove_migratable_orphans
    types = all.map(&:migratable_type).uniq.compact
    types.each do |type|
      klass=type.constantize
      options={class: klass, class_name: type, id: :migratable_id}
      remove_orphans options
    end
  end

  def self.remove_orphans(options)
    t_ids=all_ids options[:class]
    vs_ids=select(options[:id]).where{migratable_type == options[:class_name]}.map(&options[:id])
    diff = vs_ids - t_ids
    removed=unless diff.empty?
      where{options[:id] >> diff}.delete_all
    else
      0
    end
    ap "removed #{removed} orphaned records for #{options[:class_name]}"
  end

  def self.status(obj)
  unmigrated = V2MigrationProgress.select(:source_id).where(
      :source_table_name =~ obj.table_name, :migrated_at.eq=>nil).map(&:source_id)
    p unmigrated.empty? ? "successfully migrated #{obj.base_class.to_s}" :
      "the following #{unmigrated.count} #{obj.base_class.to_s} failed migration:
      #{unmigrated.join(', ')}"
  end

  def self.all_ids(klass)
    klass.select(klass.primary_key.to_sym).map(&("#{klass.primary_key}".to_sym))
  end

  def self.migratable_types
    all.map(&:migratable_type).uniq
  end

  def source_obj
    o=OldSite::Base.descendants.find{|c|
      c.table_name==source_table_name}
    eval "#{o.name}.find_by_#{o.primary_key}(source_id)"
  end
end
