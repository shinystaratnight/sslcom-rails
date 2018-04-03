namespace 'reminder' do
  desc "Sending a reminder to claim their 2 years prepaid cert to customers who first cert would be 3 years and 60 days before expiration."
  task reminder_expiring_customer: :environment do
    SslAccount.unscoped.order('created_at').includes(
        [:stored_preferences, {:certificate_orders =>
                                   [:orders, :certificate_contents=>
                                       {:csr=>:signed_certificates}]}]).find_in_batches(batch_size: 250) do |batch_list|
      desc "Filtering out expiring certs"
      e_certs = batch_list.map{|batch| batch.expiring_certificates_for_old}.reject{|e|e.empty?}.flatten
      digest = {}
      SslAccount.send_notify(e_certs, digest)
    end
  end
  desc "exiting reminder app"
end