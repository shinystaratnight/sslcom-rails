namespace 'cancan' do
  desc "Loading all models and their related controller methods in permissions table."
  task(:permissions => :environment) do
    write_permission("all", "manage", "Everything", "All operations", true)

    controllers = Dir.new("#{Rails.root}/app/controllers").entries
    controllers.each do |controller|
      if controller =~ /_controller/
        foo_bar = controller.camelize.gsub(".rb","").constantize.new
      end
    end
    # You can change ApplicationController for a super-class used by your restricted controllers
    ApplicationController.subclasses.each do |controller|
      if controller.respond_to?(:permission)
        clazz, description = controller.permission
        write_permission(clazz, "manage", description, "All operations")
        controller.action_methods.each do |action|
          if action.to_s.index("_callback").nil?
            action_desc, cancan_action = eval_cancan_action(action)
            write_permission(clazz, cancan_action, description, action_desc)
          end
        end
      end
    end
  end
end

  def eval_cancan_action(action)
    case action.to_s
      when "index", "show", "search"
        cancan_action = "read"
        action_desc = I18n.t :read
      when "create", "new"
        cancan_action = "create"
        action_desc = I18n.t :create
      when "edit", "update"
        cancan_action = "update"
        action_desc = I18n.t :edit
      when "delete", "destroy"
        cancan_action = "delete"
        action_desc = I18n.t :delete
      else
        cancan_action = action.to_s
        action_desc = "Other: " << cancan_action
    end
    return action_desc, cancan_action
  end

  def write_permission(class_name, cancan_action, name, description, force_id_1 = false)
    permission  = Permission.where(subject_class: class_name, action: cancan_action).first
    if not permission
      permission = Permission.new
      permission.id = 1 if force_id_1
      permission.subject_class =  class_name
      permission.action = cancan_action
      permission.name = name
      permission.description = description
      permission.save
    else
      permission.name = name
      permission.description = description
      permission.save
    end
  end