class SignedCertificate < ActiveRecord::Base
  using_access_control
  serialize :organization_unit
  belongs_to :parent, :foreign_key=>:parent_id,
    :class_name=> 'SignedCertificate', :dependent=>:destroy
  belongs_to :csr
  validates_presence_of :body, :if=> Proc.new{|r| !r.parent_cert}
  validates_presence_of :csr, :on=>:save
  validate :proper_certificate?, :if=>
    Proc.new{|r| !r.parent_cert && !r.body.blank?}
  validate :same_as_previously_signed_certificate?, :if=> '!csr.blank?'

  attr :parsed

  def body=(certificate)
    return if certificate.blank?
    self[:body] = certificate
    ssl_util = Savon::Client.new AppConfig.certificate_parser_wsdl
    begin
      response = ssl_util.parse_certificate do |soap|
        soap.body = {:csr => certificate}
      end
    rescue
    else
      self[:parent_cert] = false
      @parsed = response.to_hash[:multi_ref]
      unless @parsed.is_a? Array
        return
      end
      certs = []
      1.times do |i|
        certs[i] = (i == 0) ? self : certs[i-1].create_parent(:parent_cert=>true)
        certs[i][:common_name] = @parsed[i][:cn][:cn]
        certs[i][:organization] = @parsed[i][:o][:o]
        certs[i][:organization_unit] = @parsed[i][:ou][:ou]
        certs[i][:address1] = @parsed[i][:street][:street]
        certs[i][:state] = @parsed[i][:st][:st]
        certs[i][:locality] = @parsed[i][:l][:l]
        certs[i][:country] = @parsed[i][:c][:c]
        certs[i][:signature] = @parsed[i][:signature]
        certs[i][:fingerprint] = @parsed[i][:fingerprint]
        certs[i][:fingerprint_sha] = @parsed[i][:fingerprint_sha]
        certs[i][:effective_date] = @parsed[i][:eff_date]
        certs[i][:expiration_date] = @parsed[i][:exp_date]
        certs[i].save unless i==0
      end
    end
  end

  def ssl_account
    csr.certificate_content.certificate_order.ssl_account
  end

  def expired?
    return false unless expiration_date
    expiration_date < (Time.new)
  end

  def create_signed_cert_zip_bundle
    co=csr.certificate_content.certificate_order
    t = Tempfile.new(friendly_common_name+'.zip')
    # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
    Zip::ZipOutputStream.open(t.path) do |zos|
      co.certificate_chain_names.each do |file_name|
        file=File.new(AppConfig.intermediate_certs_path+file_name.strip, "r")
        # Create a new entry with some arbitrary name
        zos.put_next_entry(file_name)
        # Add the contents of the file, don't read the stuff linewise if its binary, instead use direct IO
        zos.print IO.read(file.path)
      end
      zos.put_next_entry(friendly_common_name+'.crt')
      zos.print body
    end
    t
  end

  def send_processed_certificate
    file = create_signed_cert_zip_bundle
    co=csr.certificate_content.certificate_order
    co.processed_recipients.each do |c|
      OrderNotifier.deliver_processed_certificate_order(c, co, file)
      OrderNotifier.deliver_site_seal_approve(c, co)
    end
  end

  def friendly_common_name
    common_name.gsub('*', 'STAR').gsub('.', '_')
  end

  def certificate_order
    csr.certificate_content.certificate_order
  end

  def expiration_date_js
    expiration_date.to_s
  end

  def created_at_js
    created_at.to_s
  end

  private

  def proper_certificate?
    errors.add_to_base 'invalid certificate' unless @parsed.is_a?(Array)
  end

  def same_as_previously_signed_certificate?
    if csr.signed_certificate && csr.signed_certificate.body == body
#      errors.add_to_base "signed certificate is the same as previously saved one"
    end
  end
end

