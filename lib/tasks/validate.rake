namespace 'validate' do
  desc "Scan cname and csr hash file uploads"
  task scan_and_issue: :environment do
    CertificateOrder.unvalidated_by_scan.where{created_at > date}.find_each do |co|
      # find unvalidates cname and http hash certificate_orders
      if co.domains_validated?
        co.validate!
        api_log_entry=co.apply_for_certificate(mapping: cc.ca)
        cc.issue! if api_log_entry and !api_log_entry.certificate_chain.blank?
      end
    end
  end
  desc "exiting scan_and_issue"
end