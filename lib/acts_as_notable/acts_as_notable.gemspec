# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts_as_notable}
  s.version = "1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Caleb Adam Haye"]
  s.autorequire = %q{acts_as_notable}
  s.date = %q{2009-10-24}
  s.description = %q{Plugin/gem that provides note functionality}
  s.email = %q{caleb@firecollective.com}
  s.extra_rdoc_files = ["README", "MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README", "generators/note", "generators/note/note_generator.rb", "generators/note/templates", "generators/note/templates/note.rb", "generators/note/templates/create_notes.rb", "lib/acts_as_notable.rb", "lib/note_methods.rb", "lib/notable_methods.rb", "tasks/acts_as_notable_tasks.rake", "init.rb", "install.rb"]
  s.homepage = %q{http://www.juixe.com/techknow/index.php/2006/06/18/acts-as-notable-plugin/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Plugin/gem that provides note functionality}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
