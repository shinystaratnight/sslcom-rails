class SeedWeakKeys < ActiveRecord::Migration
  def up
    wk=[]
    File.open("lib/weak_keys/blacklist.RSA-1024", "r").each_line do |line|
      wk << WeakKey.new(sha1_hash: line, algorithm: "RSA", size: 1024)
    end
    WeakKey.import wk
    File.open("lib/weak_keys/blacklist.RSA-2048", "r").each_line do |line|
      wk << WeakKey.new(sha1_hash: line, algorithm: "RSA", size: 2048)
    end
    WeakKey.import wk
    File.open("lib/weak_keys/blacklist.RSA-4096", "r").each_line do |line|
      wk << WeakKey.new(sha1_hash: line, algorithm: "RSA", size: 4096)
    end
    WeakKey.import wk
  end

  def down
    WeakKey.delete_all
  end
end
