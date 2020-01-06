# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
begin
  Ca.create(id: 1, ref: "0", friendly_name: "SSL.com Shadow", profile_name: "Management CA", algorithm: "rsa", description: "SSL.com Shadow", profile_type: "certificate")
rescue => exception
  fail exception unless Rails.env.test?
end

User.destroy_all if Rails.env.test?
