namespace :csrs do
  desc "TODO"
  task refs: :environment do
    Csr.find_each do |csr|
      csr.update_column(:ref, 'csr-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32))
    end
  end

end
