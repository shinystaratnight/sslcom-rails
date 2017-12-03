class Db  < ActiveRecord::Base

  # create initial local and global sandboxes
  # be sure db sandbox_ssl_com exists and is accessible
  def self.init_sandboxes
    %w(com local).each do |extension|
      sandbox_db=Db.find_or_create_by name: "sandbox_ssl_com"
      Sandbox.find_or_create_by host: "sandbox.ssl.#{extension}", api_host: "sws-test.sslpki.#{extension}",
                     name: "Production Sandbox Site", db_id: sandbox_db.id # production sandbox
      Sandbox.find_or_create_by host: "sandbox2.ssl.#{extension}", api_host: "sws-test2.sslpki.#{extension}", name: "Development Sandbox Site",
                     db_id: sandbox_db.id #dev sandbox
      #to prevent recursive look ups, create the Websites and Db in the sandbox db
      Sandbox.find_by_host("sandbox2.ssl.#{extension}").use_database #switch to the sandbox db
      sandbox_db=Db.find_or_create_by name: "sandbox_ssl_com"
      Sandbox.find_or_create_by host: "sandbox.ssl.#{extension}", api_host: "sws-test.sslpki.#{extension}",
                     name: "Production Sandbox Site", db_id: sandbox_db.id
      Sandbox.find_or_create_by host: "sandbox2.ssl.#{extension}", api_host: "sws-test2.sslpki.#{extension}",
                     name: "Development Sandbox Site", db_id: sandbox_db.id
      Sandbox.find_by_host("sandbox2.ssl.#{extension}").revert_database #switch back
    end
  end
end