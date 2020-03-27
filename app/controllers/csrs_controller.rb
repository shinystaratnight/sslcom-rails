class CsrsController < ApplicationController
  before_action :find_csr, only:[:http_dcv_file, :verification_check, :create_new_unique_value]
  filter_access_to :all, :attribute_check=>true, except: [:verification_check]
  filter_access_to :country_codes, :http_dcv_file, :all_domains, :check_validation, :create_new_unique_value, :require=>[:create] #anyone can create read creates csrs, thus read this

  # PUT /csrs/1
  # PUT /csrs/1.xml
  def update
    respond_to do |format|
      if @csr.update_attributes(params[:csr])
        @csr.certificate_content.tap do |cc|
          cc.update_attribute(:workflow_state, "contacts_provided") if cc.pending_validation?
        end
        format.html {
          flash[:notice] = 'Csr was successfully updated.'
          redirect_to(@csr.certificate_content.certificate_order) }
        format.xml  { head :ok }
        format.js   { render :json=>@csr.to_json(:include=>:signed_certificate)}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @csr.errors, :status => :unprocessable_entity }
        format.js   { render :json=>@csr.errors.to_json}
      end
    end
  end

  def http_dcv_file
    tmp_file="#{Rails.root}/tmp/#{@csr.md5_hash}.txt"
    File.open(tmp_file, 'wb') do |f|
      f.write @csr.dcv_contents
    end
    send_file tmp_file, :type => 'text', :disposition => 'attachment',
      :filename =>@csr.md5_hash+".txt"
  end

  def verification_check
    http_or_s = false

    if params[:ref]
      if cc = CertificateContent.find_by_ref(params[:ref])
        cn = cc.certificate_names.find_by_name(params[:dcv].split(':')[1])

        if cn
          cn.new_name params['new_name']
          http_or_s = cn.dcv_verify(params[:protocol])

          if http_or_s.to_s == 'true'
            dcv = cn.domain_control_validations.last
            if dcv && (dcv.dcv_method == params[:protocol])
              dcv.satisfy! unless dcv.satisfied?
            else
              dcv=cn.domain_control_validations.create(
                  dcv_method: params[:protocol],
                  candidate_addresses: nil,
                  failure_action: 'ignore')
              dcv.satisfy!
            end
          elsif http_or_s.nil?
            http_or_s = false
          end
        end
      end
    else
      cn = CertificateName.includes(:domain_control_validations).find_by_id(params[:choose_cn])
      csr = Csr.find_by_id(params[:selected_csr])

      http_or_s = CertificateName.dcv_verify(protocol: params[:protocol],
                                 https_dcv_url: "https://#{cn.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
                                 http_dcv_url: "http://#{cn.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
                                 cname_origin: "#{csr.dns_md5_hash}.#{cn.name}",
                                 cname_destination: "#{csr.cname_destination}",
                                 csr: csr,
                                 ca_tag: csr.ca_tag)

      if http_or_s.to_s == 'true'
        dcv = cn.domain_control_validations.last

        if dcv && (dcv.dcv_method == params[:protocol])
          dcv.satisfy! unless dcv.satisfied?
        else
          dcv=csr.domain_control_validations.create(
              dcv_method: params[:protocol],
              candidate_addresses: nil,
              failure_action: 'ignore')
          dcv.satisfy!
        end
      elsif http_or_s.nil?
        http_or_s = false
      end
    end

    respond_to do |format|
      format.html { render inline: http_or_s.to_s }
    end
  end

  def all_domains
    returnObj = {}
    selected_csr = Csr.find_by_ref(params[:ref])
    returnObj['common_name'] = selected_csr.common_name
    returnObj['subject_alternative_names'] = selected_csr.subject_alternative_names
    returnObj['csr_body'] = selected_csr.body
    returnObj['days_left'] = selected_csr.days_left
    returnObj['public_key_sha1'] = selected_csr.public_key_sha1

    render :json => returnObj
  end

  def check_validation
    domains = params[:domains]
    public_key_sha1 = params[:public_key_sha1] || ''
    returnObj = {}

    domains.each do |domain|
      exist_validated = false

      CertificateName.find_by_domains(domain).each do |name|
        last_dcv = name.domain_control_validations.last

        if last_dcv && last_dcv.satisfied?
          if last_dcv.dcv_method == 'email'
            exist_validated = true
            break
          elsif last_dcv.csr && (last_dcv.cached_csr_public_key_sha1 == public_key_sha1)
            exist_validated = true
            break
          end
        end
      end

      returnObj[domain] = exist_validated ? 'true' : 'false'
    end

    render :json => returnObj
  end

  def create_new_unique_value
    returnObj = {}
    same_exist = @csr.csr_unique_values.where(unique_value: params[:new_unique_value]).first

    if same_exist
      returnObj['same'] = true
    else
      @csr.csr_unique_values.create(unique_value: params[:new_unique_value])

      returnObj['cname_destination'] = @csr.cname_destination
      returnObj['dns_sha2_hash'] = @csr.dns_sha2_hash
    end


    render :json => returnObj
  end

  private

  def find_csr
    @csr=Csr.find(params[:id])
  end
end
