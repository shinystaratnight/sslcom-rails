collection @site_checks
child :all_certificates=>:peer_certificates do
    glue :subject do
        attributes :common_name=>:primary_name
    end
    attributes :not_before, :not_after, :strength, :subject_key_identifier
    node :subject do |c|
        c.subject.to_a
    end
end
attributes :result=>:openssl_verify_result, :s_client_issuers=>:trust_chain
