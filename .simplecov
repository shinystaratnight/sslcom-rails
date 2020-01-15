SimpleCov.minimum_coverage 10
SimpleCov.refuse_coverage_drop
SimpleCov.enable_coverage :branch

SimpleCov.start 'rails' do
  filters.clear
  # add_filter do |src|
  #   !(src.filename =~ /^#{SimpleCov.root}/) unless src.filename =~ /my_engine/
  # end
  add_filter %r{^/test/}
  add_filter %r{^/config/}
  add_filter %r{^/db/}
  add_filter %r{^/vendor/}
  add_filter %r{^/public/}
  add_filter %r{^/features/}
  add_filter %r{^/lib/acts_as}
  add_filter %r{^/lib/in_place_editing}
  add_filter %r{^/lib/dynamic_form}
  add_filter %r{^/lib/preferences}
  add_filter %r{^/app/assets/}
  add_filter %r{^/app/paths/}
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Helpers', 'app/helpers'
  add_group 'Serializers', 'app/serializers'
end
