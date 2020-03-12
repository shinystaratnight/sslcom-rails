# frozen_string_literal: true

require('rails_helper')
describe(CertificateOrder) do
  before(:all) do
    initialize_roles
    initialize_triggers
    initialize_server_software
  end

  subject { CertificateOrder.new }

  it { should belong_to(:assignee).class_name('User') }
  it { should belong_to(:folder) }
  it { should belong_to(:site_seal) }
  it { should belong_to(:parent).class_name('CertificateOrder') }
  it { should belong_to(:ssl_account) }
  it { should belong_to(:validation) }
  it { should have_many(:registrants).through(:certificate_contents) }
  it { should have_many(:locked_registrants).through(:certificate_contents) }
  it { should have_many(:certificate_contacts).through(:certificate_contents) }
  it { should have_many(:domain_control_validations).through(:certificate_names) }
  it { should have_many(:csrs).through(:certificate_contents).source(:csr) }
  it { should have_many(:csr_unique_values).through(:csrs) }
  it { should have_many(:attestation_certificates).through(:certificate_contents) }
  it { should have_many(:signed_certificates).through(:csrs).source(:signed_certificate) }
  it { should have_many(:attestation_issuer_certificates).through(:certificate_contents) }
  it { should have_many(:shadow_certificates).through(:csrs).class_name('ShadowSignedCertificate') }
  it { should have_many(:ca_certificate_requests).through(:csrs) }
  it { should have_many(:ca_api_requests).through(:csrs) }
  it { should have_many(:sslcom_ca_requests).through(:csrs) }
  it { should have_many(:sub_order_items) }
  it { should have_many(:product_variant_items).through(:sub_order_items) }
  it { should have_many(:orders).through(:line_items) }
  it { should have_many(:other_party_validation_requests).class_name('OtherPartyValidationRequest') }
  it { should have_many(:ca_retrieve_certificates) }
  it { should have_many(:ca_mdc_statuses) }
  it { should have_many(:jois).class_name('Joi') }
  it { should have_many(:app_reps).class_name('AppRep') }
  it { should have_many(:physical_tokens) }
  it { should have_many(:url_callbacks).through(:certificate_contents) }
  it { should have_many(:taggings) }
  it { should have_many(:tags).through(:taggings) }
  it { should have_many(:notification_groups_subjects) }
  it { should have_many(:notification_groups).through(:notification_groups_subjects) }
  it { should have_many(:certificate_order_tokens) }
  it { should have_many(:certificate_order_managed_csrs) }
  it { should have_many(:managed_csrs).through(:certificate_order_managed_csrs) }
  it { should have_many(:certificate_order_domains) }
  it { should have_many(:managed_domains).through(:certificate_order_domains).source(:domain) }
  it { should have_one(:locked_recipient) }
  it { should have_one(:renewal) }

  context('scopes') do
    describe('search_with_csr') do
      let!(:cert) { create(:certificate_with_certificate_order, :premiumssl) }
      let!(:co) { create(:certificate_order, :with_contents) }

      before(:each) do
        co.stubs(:certificate).returns(cert)
        # CertificateContent.any_instance.stubs(:domain_validation).returns(true)
        SslAccount.any_instance.stubs(:initial_setup).returns(true)
      end

      %w[common_name organization subject_alternative_names locality country strength].each do |field|
        it("filters by csr.#{field}") do
          csr = co.certificate_contents[0].csrs[0]
          query = case field
                  when 'subject_alternative_names'
                    "#{field}:'#{csr[field.to_sym].join(', ')}'"
                  when 'organization', 'locality'
                    "#{field}:'#{csr[field.to_sym].gsub(' ', '')}'"
                  else
                    "#{field}:'#{csr[field.to_sym]}'"
                  end
          queried = CertificateOrder.search_with_csr(query)
          expect(true).to(eq(queried.include?(co)))
        end
      end

      CertificateContent.workflow_spec.states.each_key do |status|
        it("filters on status #{status}") do
          co.certificate_content.update_attribute(workflow_state: status)
          query = "status:'#{status}'"
          queried = CertificateOrder.search_with_csr(query)
          queried.each do |q|
            expect(q.certificate_contents[0].workflow_state).to(eq(status.to_s))
          end
        end
      end

      it('filters by csr.decoded') do
        query = "decoded:'3d:85:97:16:20:81:80:83:3a:6f:26:94:c6:5a:38'"
        queried = CertificateOrder.search_with_csr(query)
        queried.include?(co).should eq true
      end

      %w[postal_code signature fingerprint address login email account_number organization_unit state].each do |field|
        it("filters by signed_certificate.#{field}") do
          sc = co.certificate_contents[0].csrs[0].signed_certificates[0]
          query = case field
                  when 'account_number'
                    "account_number:'#{co.ssl_account[:acct_number]}'"
                  when 'login' then
                    (co.ssl_account.users << create(:user))
                    "login:'#{co.ssl_account.users[0][:login]}'"
                  when 'email' then
                    (co.ssl_account.users << create(:user))
                    "email:'#{co.ssl_account.users[0][:email]}'"
                  when 'address'
                    "address:'#{sc[:address1]}'"
                  else
                    "#{field}:'#{sc[field.to_sym]}'"
                  end
          queried = CertificateOrder.search_with_csr(query)
          queried.include?(co).should eq true
        end
      end

      it('filters by signed_certificate.expiration_date') do
        start = DateTime.now.strftime('%m/%d/%Y')
        stop = (DateTime.now + 30.days).strftime('%m/%d/%Y')
        range = [start, stop].join('-')
        query = "expires_at:'#{range}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.include?(co).should eq true
      end

      it('filters by signed_certificate.created_at') do
        start = (DateTime.now - 2.days).strftime('%m/%d/%Y')
        stop = (DateTime.now + 30.days).strftime('%m/%d/%Y')
        range = [start, stop].join('-')
        query = "issued_at:'#{range}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.include?(co).should eq true
      end

      it('filters by created_at') do
        start = (DateTime.now - 2.days).strftime('%m/%d/%Y')
        stop = (DateTime.now + 30.days).strftime('%m/%d/%Y')
        range = [start, stop].join('-')
        query = "created_at:'#{range}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.include?(co).should eq true
      end

      it('filters on certificate_content.tags') do
        co.certificate_contents[0].stubs(:tags).returns(build_stubbed_list(:tag, 2))
        query = "cc_tags:'#{co.certificate_contents[0].tags[0].name}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.each do |q|
          expect(q.certificate_contents[0].tags[0].name).to(eq(co.certificate_contents[0].tags[0].name))
        end
      end

      it('filters on certificate_content.duration') do
        query = "duration:'#{co.certificate_contents[0].duration}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.each do |q|
          expect(q.certificate_contents[0].duration).to(eq(co.certificate_contents[0].duration))
        end
      end

      it('filters on certificate_content.product') do
        query = "product:'#{cert[:product]}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.each do |q|
          expect(q.certificate_contents[0].product).to(eq(cert.product))
        end
      end

      it('filters on tags') do
        tagged_order = create(:certificate_order, include_tags: true, sub_order_items: [cert.product_variant_groups[0].product_variant_items[0].sub_order_item])
        query = "co_tags:'#{tagged_order.tags[0].name}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.each { |q| expect(q.tags[0].name).to(eq(tagged_order.tags[0].name)) }
      end

      it('filters correctly for is_test:false?') do
        query = "is_test:'false'"
        queried = CertificateOrder.search_with_csr(query)
        expect(true).to(eq(queried.include?(co)))
      end

      it('filters correctly for is_test:true?') do
        co.update(is_test: true)
        query = "is_test:'true'"
        queried = CertificateOrder.search_with_csr(query)
        expect(true).to(eq(queried.include?(co)))
      end

      it('filters on folder_id') do
        query = "folder_ids:'#{[co.folder_id]}'"
        queried = CertificateOrder.search_with_csr(query)
        queried.each { |q| expect(q.folder_id).to(eq(co.folder_id)) }
      end

      %w[external_order_number ref notes].each do |field|
        it("filters on #{field}") do
          query = "#{field}:'#{co[field.to_sym]}'"
          queried = CertificateOrder.search_with_csr(query)
          queried.each { |q| expect(q[field.to_sym]).to(eq(co[field.to_sym])) }
        end
      end

      %i[in_transit received in_possession].each do |token_status|
        it("filters by physical_tokens:#{token_status}") do
          sc = co.certificate_contents[0].csrs[0].signed_certificates[0]
          (co.physical_tokens << create(:physical_token, certificate_order: co, signed_certificate: sc, workflow_state: token_status))
          query = "physical_tokens:'#{token_status}'"
          queried = CertificateOrder.search_with_csr(query)
          queried.each do |q|
            expect(q.physical_tokens[0].workflow_state).to(eq(token_status.to_s))
          end
        end
      end
    end
  end
end
