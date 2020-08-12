#
# Populate reject keys tables
#
namespace :reject_keys do
  desc "populate reject_keys table with Debian weak keys"
  task populate: :environment do
    weak_keys = []
    File.foreach("lib/reject_keys/blacklist.RSA-2048") do |line|
      weak_keys << WeakKey.new(fingerprint: line.chomp, algorithm: "RSA", size: 2048, source: 'blacklist-openssl', type: 'WeakKey')
    end
    File.foreach("lib/reject_keys/blacklist.RSA-4096") do |line|
      weak_keys << WeakKey.new(fingerprint: line.chomp, algorithm: "RSA", size: 4096, source: 'blacklist-openssl', type: 'WeakKey')
    end
    WeakKey.import weak_keys
  end
end
