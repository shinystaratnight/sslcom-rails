require 'activerecord'

# ActsAsNotable
module Juixe
  module Acts #:nodoc:
    module Notable #:nodoc:

      def self.included(base)
        base.extend ClassMethods  
      end

      module ClassMethods
        def acts_as_notable
          has_many :notes, :as => :notable, :dependent => :destroy
          include Juixe::Acts::Notable::InstanceMethods
          extend Juixe::Acts::Notable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        # Helper method to lookup for notes for a given object.
        # This method is equivalent to obj.notes.
        def find_notes_for(obj)
          notable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
         
          Note.find(:all,
            :conditions => ["notable_id = ? and notable_type = ?", obj.id, notable],
            :order => "created_at DESC"
          )
        end
        
        # Helper class method to lookup notes for
        # the mixin notable type written by a given user.  
        # This method is NOT equivalent to Note.find_notes_for_user
        def find_notes_by_user(user) 
          notable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Note.find(:all,
            :conditions => ["user_id = ? and notable_type = ?", user.id, notable],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to sort notes by date
        def notes_ordered_by_submitted
          Note.find(:all,
            :conditions => ["notable_id = ? and notable_type = ?", id, self.class.name],
            :order => "created_at DESC"
          )
        end
        
        # Helper method that defaults the submitted time.
        def add_note(note)
          notes << note
        end
      end
      
    end
  end
end

ActiveRecord::Base.send(:include, Juixe::Acts::Notable)
