# ==== Schema information ====

# t.string   "name"
# t.integer  "owner_id"
# t.string   "owner_type"
# t.integer  "group_id"
# t.string   "group_type"
# t.string   "value",
# t.datetime "created_at"
# t.datetime "updated_at"

FactoryBot.define do
  factory :preference do
    name { 'reminder_notice_triggers' }
    owner_id { }
    owner_type { 'SslAccount' }
    group_type { 'ReminderTrigger' }
    value { }
  end
end
