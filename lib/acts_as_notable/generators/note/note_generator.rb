class NoteGenerator < Rails::Generator::Base
   def manifest
     record do |m|
       m.directory 'app/models'
       m.file 'note.rb', 'app/models/note.rb'
       m.migration_template "create_notes.rb", "db/migrate"
     end
   end
   # ick what a hack.
   def file_name
     "create_notes"
   end
 end
