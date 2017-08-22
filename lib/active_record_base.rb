module ActiveRecord
  class Base
    def self.inherited(klass)
      super
      klass.send :has_many, :owner_system_audits, :as => :owner, class_name: "SystemAudit"
      klass.send :has_many, :target_system_audits, :as => :target, class_name: "SystemAudit"
    end

    def system_audits
      target_system_audits.merge owner_system_audits
    end
  end
end
