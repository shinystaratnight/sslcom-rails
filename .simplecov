SimpleCov.start 'rails' do
  filters.clear
  add_filter %r{^/test/}
  add_filter %r{^/spec/}
  add_filter %r{^/.*declarative_authorization.*/}
  add_filter %r{^/.*lib/gems/.*/}
  add_filter %r{^/usr/}
  add_filter %r{^/config/}
  add_filter %r{^/db/}
  add_filter %r{^/vendor/}
  add_filter %r{^/public/}
  add_filter %r{^/features/}
  add_filter %r{^/lib/acts_as}
  add_filter %r{^/lib/in_place_editing}
  add_filter %r{^/lib/dynamic_form}
  add_filter %r{^/lib/preferences}
  add_filter %r{^/app/paths/}
  Dir['app/*'].each do |dir|
    add_group File.basename(dir).humanize, dir
  end
end
