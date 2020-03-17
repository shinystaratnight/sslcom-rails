class SeedWeakKeys < ActiveRecord::Migration
  unless Rails.env.test?
    def up
      wk=[]
      File.foreach("lib/weak_keys/blacklist.RSA-1024") do |line|
        wk << WeakKey.new(sha1_hash: line.chomp, algorithm: "RSA", size: 1024)
        break unless Rails.env.production? # record should be good enough for development
      end
      WeakKey.import wk
      File.foreach("lib/weak_keys/blacklist.RSA-2048") do |line|
        wk << WeakKey.new(sha1_hash: line.chomp, algorithm: "RSA", size: 2048)
        break unless Rails.env.production?
      end
      WeakKey.import wk
      File.foreach("lib/weak_keys/blacklist.RSA-4096") do |line|
        wk << WeakKey.new(sha1_hash: line.chomp, algorithm: "RSA", size: 4096)
        break unless Rails.env.production?
      end
      WeakKey.import wk
    end

    def down
      WeakKey.delete_all
    end
  end
end
