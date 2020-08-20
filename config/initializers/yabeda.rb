Yabeda.configure do
  default_tag :environment, Rails.env

  group :ra do
    counter :jobs_count, comment: "Total number of job executions", tags: %i[name]
    counter :external_api_total, comment: "External API calls", tags: %i[name]
    counter :external_api_error, comment: "External API errors", tags: %i[name status]
    histogram :external_api_call_duration do
      comment "External API call duration"
      unit :seconds
      tags %i[name status]
      buckets [
        0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 15,
        30, 60, 120, 300, 600
      ]
    end
    gauge :users_active, comment: "Total number of active users"
  end

  collect do
    ra.users_active.set({}, User.where(last_request_at: (10.minutes.ago..Time.now)).count)
  end
end
