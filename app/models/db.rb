# == Schema Information
#
# Table name: dbs
#
#  id       :integer          not null, primary key
#  host     :string(255)
#  name     :string(255)
#  password :string(255)
#  username :string(255)
#

class Db  < ApplicationRecord

  # create initial local and global sandboxes
  # be sure db sandbox_ssl_com exists and is accessible
  def self.init_sandboxes
    Db.delete_all
    Sandbox.delete_all
    sandbox_db=Db.create name: "sandbox_ssl_com"
    %w(com local).each do |extension|
      Sandbox.create host: "sandbox.ssl.#{extension}", api_host: "sws-test.sslpki.#{extension}",
                     name: "Production Sandbox Site", db_id: sandbox_db.id # production sandbox
      Sandbox.create host: "sandbox2.ssl.#{extension}", api_host: "sws-test2.sslpki.#{extension}", name: "Development Sandbox Site",
                     db_id: sandbox_db.id #dev sandbox
      #to prevent recursive look ups, create the Websites and Db in the sandbox db
    end
    Sandbox.find_by_host("sandbox2.ssl.local").use_database #switch to the sandbox db
    Db.delete_all
    Sandbox.delete_all
    sandbox_db=Db.create name: "sandbox_ssl_com"
    %w(com local).each do |extension|
      Sandbox.create host: "sandbox.ssl.#{extension}", api_host: "sws-test.sslpki.#{extension}",
                     name: "Production Sandbox Site", db_id: sandbox_db.id
      Sandbox.create host: "sandbox2.ssl.#{extension}", api_host: "sws-test2.sslpki.#{extension}",
                     name: "Development Sandbox Site", db_id: sandbox_db.id
      Website.revert_database #switch back
    end
  end
end
