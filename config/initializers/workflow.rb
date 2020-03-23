Workflow::Adapter::ActiveRecord::InstanceMethods.module_eval do
  # On transition the new workflow state is immediately saved in the database.
  def persist_workflow_state(new_value)
    # older Rails; beware of side effect: other (pending) attribute changes will be persisted too
    update_attribute self.class.workflow_column, new_value
  end
end
