Yabeda.configure do
  default_tag :environment, Rails.env

  group :ra do
    counter :jobs_count, comment: "Total number of job executions", tags: %i[name]
    gauge   :users_active, comment: "Total number of active users"
    gauge   :jobs_failed, comment: "Total number of failed jobs"
  end

  collect do
    ra.users_active.set({}, User.where(last_request_at: (10.minutes.ago..Time.now)).count)
    ra.jobs_failed.set({}, ActiveRecord::Base.connection.execute("SELECT COUNT(id) FROM delayed_jobs WHERE failed_at IS NOT NULL").first[0])
  end
end
