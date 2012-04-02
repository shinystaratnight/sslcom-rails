collection @site_checks
glue :certificate => :certificate do
    glue :subject do
        attributes :common_name=>:primary_name
    end
    attributes :not_before, :not_after, :strength, :subject_key_identifier
end
node :subject do |ou|
    ou.subject_to_array(ou.certificate.subject.to_s)
end
attributes :result=>:openssl_verify_result
