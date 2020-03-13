#
# Populate weak keys tables
#
namespace :weak_keys do
  desc "populate weak_keys table with Debian weak keys"
  task populate: :environment do
    wk=[]
    File.foreach("lib/weak_keys/blacklist.RSA-1024") do |line|
      wk << WeakKey.new(sha1_hash: line.chomp, algorithm: "RSA", size: 1024)
    end
    WeakKey.import wk
    File.foreach("lib/weak_keys/blacklist.RSA-2048") do |line|
      wk << WeakKey.new(sha1_hash: line.chomp, algorithm: "RSA", size: 2048)
    end
    WeakKey.import wk
    File.foreach("lib/weak_keys/blacklist.RSA-4096") do |line|
      wk << WeakKey.new(sha1_hash: line.chomp, algorithm: "RSA", size: 4096)
    end
    WeakKey.import wk
  end
end

