module ActiveRecord
  class Base
    def self.inherited(klass)
      super
      klass.send :has_many, :owner_system_audits, :as => :owner, class_name: "SystemAudit"
      klass.send :has_many, :target_system_audits, :as => :target, class_name: "SystemAudit"
    end

    # UNION in Rails 4 https://stackoverflow.com/questions/6686920/activerecord-query-union
    def system_audits
      SystemAudit.from("(#{target_system_audits.to_sql} UNION #{owner_system_audits.to_sql}) AS system_audits")
    end
  end
end
