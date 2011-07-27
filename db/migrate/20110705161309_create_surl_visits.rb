class CreateSurlVisits < ActiveRecord::Migration
  def self.up
    create_table  :surl_visits, force: true do |t|
      t.references :surl
      t.references :visitor_token
      t.string     :referer_host
      t.string     :referer_address
      t.string     :request_uri
      t.string     :http_user_agent
      t.string     :result
      t.timestamps
    end
  end

  def self.down
    drop_table    :surl_visits
  end
end
