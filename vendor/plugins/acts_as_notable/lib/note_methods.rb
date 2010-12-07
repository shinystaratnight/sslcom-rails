module ActsAsNotable
  # including this module into your Note model will give you finders and named scopes
  # useful for working with Notes.
  # The named scopes are:
  #   in_order: Returns notes in the order they were created (created_at ASC).
  #   recent: Returns notes by how recently they were created (created_at DESC).
  #   limit(N): Return no more than N notes.
  module Note
    
    def self.included(note_model)
      note_model.extend Finders
      note_model.named_scope :in_order, {:order => 'created_at ASC'}
      note_model.named_scope :recent, {:order => "created_at DESC"}
      note_model.named_scope :limit, lambda {|limit| {:limit => limit}}
    end
    
    module Finders
      # Helper class method to lookup all notes assigned
      # to all notable types for a given user.
      def find_notes_by_user(user)
        find(:all,
          :conditions => ["user_id = ?", user.id],
          :order => "created_at DESC"
        )
      end

      # Helper class method to look up all notes for 
      # notable class name and notable id.
      def find_notes_for_notable(notable_str, notable_id)
        find(:all,
          :conditions => ["notable_type = ? and notable_id = ?", notable_str, notable_id],
          :order => "created_at DESC"
        )
      end

      # Helper class method to look up a notable object
      # given the notable class name and id 
      def find_notable(notable_str, notable_id)
        notable_str.constantize.find(notable_id)
      end
    end
  end
end