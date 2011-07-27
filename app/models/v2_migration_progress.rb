class V2MigrationProgress < ActiveRecord::Base
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

  def self.find_by_migratable(migratable, which=:first)
    find(which) do |v|
      v.migratable_type==migratable.class.to_s
      v.migratable_id==migratable.id
    end
  end

  def self.find_by_migratable_and_source_table_name(
      migratable, source_table_name, which=:first)
    find(which) do |v|
      v.migratable_type==migratable.class.to_s
      v.migratable_id==migratable.id
      v.source_table_name==source_table_name
    end
  end

  def self.remove_orphans(legacy)
    l_ids=legacy_ids legacy
    vs_ids=select(:source_id).where(:source_table_name.eq => legacy.table_name).map(&:source_id)
    if vs_ids.count > l_ids.count
      diff = vs_ids - l_ids
      where(:source_id + diff).delete_all
    else
      0
    end
  end

  def self.legacy_ids(legacy)
    legacy.select(legacy.primary_key.to_sym).map(&("#{legacy.primary_key}".to_sym))
  end

  def source_obj
    o=OldSite::Base.descendants.find{|c|
      c.table_name==source_table_name}
    eval "#{o.name}.find_by_#{o.primary_key}(source_id)"
  end
end
