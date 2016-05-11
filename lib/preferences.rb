require 'preferences/preference_definition'

# Adds support for defining preferences on ActiveRecord models.
#
# == Saving preferences
#
# Preferences are not automatically saved when they are set.  You must save
# the record that the preferences were set on.
#
# For example,
#
#   class User < ActiveRecord::Base
#     preference :notifications
#   end
#
#   u = User.new(:login => 'admin', :prefers_notifications => false)
#   u.save!
#
#   u = User.find_by_login('admin')
#   u.attributes = {:prefers_notifications => true}
#   u.save!
#
# == Validations
#
# Since the generated accessors for a preference allow the preference to be
# treated just like regular ActiveRecord attributes, they can also be
# validated against in the same way.  For example,
#
#   class User < ActiveRecord::Base
#     preference :color, :string
#
#     validates_presence_of :preferred_color
#     validates_inclusion_of :preferred_color, :in => %w(red green blue)
#   end
#
#   u = User.new
#   u.valid?                        # => false
#   u.errors.on(:preferred_color)   # => "can't be blank"
#
#   u.preferred_color = 'white'
#   u.valid?                        # => false
#   u.errors.on(:preferred_color)   # => "is not included in the list"
#
#   u.preferred_color = 'red'
#   u.valid?                        # => true
module Preferences
  module MacroMethods
    # Defines a new preference for all records in the model.  By default,
    # preferences are assumed to have a boolean data type, so all values will
    # be typecasted to true/false based on ActiveRecord rules.
    #
    # Configuration options:
    # * <tt>:default</tt> - The default value for the preference. Default is nil.
    # * <tt>:group_defaults</tt> - Defines the default values to use for various
    #   groups.  This should map group_name -> defaults.  For ActiveRecord groups,
    #   use the class name.
    #
    # == Examples
    #
    # The example below shows the various ways to define a preference for a
    # particular model.
    #
    #   class User < ActiveRecord::Base
    #     preference :notifications, :default => false
    #     preference :color, :string, :default => 'red', :group_defaults => {:car => 'black'}
    #     preference :favorite_number, :integer
    #     preference :data, :any # Allows any data type to be stored
    #   end
    #
    # All preferences are also inherited by subclasses.
    #
    # == Associations
    #
    # After the first preference is defined, the following associations are
    # created for the model:
    # * +stored_preferences+ - A collection of all the custom preferences
    #   specified for a record.  This will not include default preferences
    #   unless they have been explicitly set.
    #
    # == Named scopes
    #
    # In addition to the above associations, the following named scopes get
    # generated for the model:
    # * +with_preferences+ - Finds all records with a given set of preferences
    # * +without_preferences+ - Finds all records without a given set of preferences
    #
    # In addition to utilizing preferences stored in the database, each of the
    # above scopes also take into account the defaults that have been defined
    # for each preference.
    #
    # Example:
    #
    #   User.with_preferences(:notifications => true)
    #   User.with_preferences(:notifications => true, :color => 'blue')
    #
    #   # Searching with group preferences
    #   car = Car.find(:first)
    #   User.with_preferences(car => {:color => 'blue'})
    #   User.with_preferences(:notifications => true, car => {:color => 'blue'})
    #
    # == Generated accessors
    #
    # In addition to calling <tt>prefers?</tt> and +preferred+ on a record,
    # you can also use the shortcut accessor methods that are generated when a
    # preference is defined.  For example,
    #
    #   class User < ActiveRecord::Base
    #     preference :notifications
    #   end
    #
    # ...generates the following methods:
    # * <tt>prefers_notifications?</tt> - Whether a value has been specified, i.e. <tt>record.prefers?(:notifications)</tt>
    # * <tt>prefers_notifications</tt> - The actual value stored, i.e. <tt>record.prefers(:notifications)</tt>
    # * <tt>prefers_notifications=(value)</tt> - Sets a new value, i.e. <tt>record.write_preference(:notifications, value)</tt>
    # * <tt>prefers_notifications_changed?</tt> - Whether the preference has unsaved changes
    # * <tt>prefers_notifications_was</tt> - The last saved value for the preference
    # * <tt>prefers_notifications_change</tt> - A list of [original_value, new_value] if the preference has changed
    # * <tt>prefers_notifications_will_change!</tt> - Forces the preference to get updated
    # * <tt>reset_prefers_notifications!</tt> - Reverts any unsaved changes to the preference
    #
    # ...and the equivalent +preferred+ methods:
    # * <tt>preferred_notifications?</tt>
    # * <tt>preferred_notifications</tt>
    # * <tt>preferred_notifications=(value)</tt>
    # * <tt>preferred_notifications_changed?</tt>
    # * <tt>preferred_notifications_was</tt>
    # * <tt>preferred_notifications_change</tt>
    # * <tt>preferred_notifications_will_change!</tt>
    # * <tt>reset_preferred_notifications!</tt>
    #
    # Notice that there are two tenses used depending on the context of the
    # preference.  Conventionally, <tt>prefers_notifications?</tt> is better
    # for accessing boolean preferences, while +preferred_color+ is better for
    # accessing non-boolean preferences.
    #
    # Example:
    #
    #   user = User.find(:first)
    #   user.prefers_notifications?         # => false
    #   user.prefers_notifications          # => false
    #   user.preferred_color?               # => true
    #   user.preferred_color                # => 'red'
    #   user.preferred_color = 'blue'       # => 'blue'
    #
    #   user.prefers_notifications = true
    #
    #   car = Car.find(:first)
    #   user.preferred_color = 'red', car   # => 'red'
    #   user.preferred_color(car)           # => 'red'
    #   user.preferred_color?(car)          # => true
    #
    #   user.save!  # => true
    def preference(name, *args)
      unless included_modules.include?(InstanceMethods)
        class_attribute :preference_definitions
        self.preference_definitions = {}

        has_many :stored_preferences, :as => :owner, :class_name => 'Preference'

        after_save :update_preferences

        # Named scopes
        scope :with_preferences, lambda {|preferences| build_preference_scope(preferences)}
        scope :without_preferences, lambda {|preferences| build_preference_scope(preferences, true)}

        extend Preferences::ClassMethods
        include Preferences::InstanceMethods
      end

      # Create the definition
      name = name.to_s
      definition = PreferenceDefinition.new(name, *args)
      self.preference_definitions[name] = definition

      # Create short-hand accessor methods, making sure that the name
      # is method-safe in terms of what characters are allowed
      name = name.gsub(/[^A-Za-z0-9_-]/, '').underscore

      # Query lookup
      define_method("preferred_#{name}?") do |*group|
        preferred?(name, group.first)
      end
      alias_method "prefers_#{name}?", "preferred_#{name}?"

      # Reader
      define_method("preferred_#{name}") do |*group|
        preferred(name, group.first)
      end
      alias_method "prefers_#{name}", "preferred_#{name}"

      # Writer
      define_method("preferred_#{name}=") do |*args|
        write_preference(*args.flatten.unshift(name))
      end
      alias_method "prefers_#{name}=", "preferred_#{name}="

      # Changes
      define_method("preferred_#{name}_changed?") do |*group|
        preference_changed?(name, group.first)
      end
      alias_method "prefers_#{name}_changed?", "preferred_#{name}_changed?"

      define_method("preferred_#{name}_was") do |*group|
        preference_was(name, group.first)
      end
      alias_method "prefers_#{name}_was", "preferred_#{name}_was"

      define_method("preferred_#{name}_change") do |*group|
        preference_change(name, group.first)
      end
      alias_method "prefers_#{name}_change", "preferred_#{name}_change"

      define_method("preferred_#{name}_will_change!") do |*group|
        preference_will_change!(name, group.first)
      end
      alias_method "prefers_#{name}_will_change!", "preferred_#{name}_will_change!"

      define_method("reset_preferred_#{name}!") do |*group|
        reset_preference!(name, group.first)
      end
      alias_method "reset_prefers_#{name}!", "reset_preferred_#{name}!"

      definition
    end
  end
end
