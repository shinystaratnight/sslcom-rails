# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

job_type :bundle_exec,  "cd :path && bundle exec script/rails runner -e :environment ':task' :output"

every 1.day, at: "12am" do
  bundle_exec "ApplicationController.flag_expired_certificate_orders"
  #bundle_exec "Malware.update"
end

every 1.day, at: "12pm" do
  bundle_exec "ApplicationController.flag_expired_certificate_orders"
end

every 20.minutes do
  bundle_exec "CertificateOrder.retrieve_ca_certs(12.hours.ago, DateTime.now)"
end

every 1.hour, at: "12:10pm" do
  bundle_exec "CertificateOrder.retrieve_ca_certs(3.days.ago, 12.hours.ago)"
end

every 6.hours, at: "12:15pm" do
  bundle_exec "CertificateOrder.retrieve_ca_certs(8.days.ago, 3.days.ago)"
end

every 12.hours, at: "12:45pm" do
  bundle_exec "CertificateOrder.retrieve_ca_certs(15.days.ago, 8.days.ago)"
end

every 1.day, at: "12:30pm" do
  bundle_exec "CertificateOrder.retrieve_ca_certs(30.days.ago, 15.days.ago)"
end
