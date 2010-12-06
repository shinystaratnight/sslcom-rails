class V2MigrationProgress < ActiveRecord::Base
  belongs_to  :migratable, :polymorphic=>true
  validates_uniqueness_of :source_id, :scope=>:source_table_name

  def self.find_by_source(obj)
    find_by_old_object(obj)
  end
  
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

  def source_obj
    o=Object.subclasses_of(OldSite::Base).find{|c|
      c.table_name==source_table_name}
    eval "#{o.name}.find_by_#{o.primary_key}(source_id)"
  end
end
