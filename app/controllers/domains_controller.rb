
class DomainsController < ApplicationController
  before_filter :require_user, :except => [:dcv_validate, :dcv_all_validate]
  before_filter :find_ssl_account
  before_filter :set_row_page, only: [:index]

  def index
    cnames = @ssl_account.certificate_names.order(:created_at).reverse_order
    @domains = (@ssl_account.domains.order(:created_at).reverse_order + cnames).paginate(@p)
  end

  def create
    res_Obj = {}
    exist_domain_names = []
    created_domains = []
    unless params[:domain_names].nil?
      domain_names = params[:domain_names].split(/[\s,']/)
      domain_names.each do |d_name|
        if @ssl_account.domain_names.include?(d_name)
          exist_domain_names << d_name
        else
          @domain = Domain.new
          @domain.name = d_name
          @domain.ssl_account_id = @ssl_account.id
          @domain.save()
          created_domains << @domain
        end
      end
    end
    res_Obj['domains'] = created_domains
    res_Obj['exist_domains'] = exist_domain_names
    render :json => res_Obj
  end

  def destroy
    @domain = current_user.ssl_account.domains.find_by(id: params[:id])
    @domain = current_user.ssl_account.certificate_names.find_by(id: params[:id]) if @domain.nil?
    @domain.destroy
    respond_to do |format|
      flash[:notice] = "Domain was successfully deleted."
      format.html { redirect_to domains_path(@ssl_slug) }
    end
  end

  def validation_request
    @domain = current_user.ssl_account.domains.find_by(id: params[:id])
    if @domain.domain_control_validations.last.try(:identifier_found)
      redirect_to domains_path(@ssl_slug)
      return
    end
    @addresses = DomainControlValidation.email_address_choices(@domain.name)
    if params[:authenticity_token]
      if params[:dcv_address]=~EmailValidator::EMAIL_FORMAT
        identifier = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
        @domain.domain_control_validations.create(dcv_method: "email", email_address: params[:dcv_address],
                                                  identifier: identifier, failure_action: "ignore", candidate_addresses: @addresses)
        OrderNotifier.dcv_email_send(nil, params[:dcv_address], identifier, [@domain.name], @domain.id, @ssl_slug, 'team').deliver
        @domain.domain_control_validations.last.send_dcv!
        flash[:notice] = "Validation email has been sent."
      end
    end
  end

  def validate_all
    if params[:authenticity_token]
      d_name_ids = params[:d_name_id]
      addresses = params[:dcv_address]
      cnames = []
      d_name_ids.each_with_index do |id, index|
        if addresses[index]=~EmailValidator::EMAIL_FORMAT
          cn = CertificateName.find_by_id(id)
          cn.domain_control_validations.create(dcv_method: "email", email_address: addresses[index])
          cnames << cn
        end
      end
      email_for_identifier = ''
      identifier = ''
      email_list = []
      identifier_list = []
      domain_ary = []
      domain_list = []
      cnames.each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv.email_address != email_for_identifier
          if domain_list.length>0
            domain_ary << domain_list
            email_list << email_for_identifier
            identifier_list << identifier
            domain_list = []
          end
          identifier = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
          email_for_identifier = dcv.email_address
        end
        domain_list << cn.name
        dcv.update_attribute(:identifier, identifier)
      end
      domain_ary << domain_list
      email_list << email_for_identifier
      identifier_list << identifier
      email_list.each_with_index do |value, key|
        OrderNotifier.dcv_email_send(nil, value, identifier_list[key], domain_ary[key], nil, @ssl_slug, 'group').deliver
      end
    end
    @all_domains = []
    @address_choices = []
    @cnames = @ssl_account.certificate_names.order(:created_at).reverse_order
    @cnames.each do |cn|
      dcv = cn.domain_control_validations.last
      next if dcv && dcv.identifier_found
      @all_domains << cn
      @address_choices << DomainControlValidation.email_address_choices(cn.name)
    end
    @domains = @ssl_account.domains.order(:created_at).reverse_order
    @domains.each do |dn|
      dcv = dn.domain_control_validations.last
      next if dcv && dcv.identifier_found
      @all_domains << dn
      @address_choices << DomainControlValidation.email_address_choices(dn.name)
    end
  end

  def remove_selected
    res_Obj = {}
    deleted_domains = []
    params[:d_name_check].each do |d_name_id|
      deleted_domains << d_name_id
      d_name = CertificateName.find_by_id(d_name_id)
      d_name.destroy
    end
    res_Obj['deleted_domains'] = deleted_domains
    render :json => res_Obj
  end

  def validate_selected
    unless params[:d_name_check]
      d_name_ids = params[:d_name_id]
      addresses = params[:dcv_address]
      cnames = []
      d_name_ids.each_with_index do |id, index|
        if addresses[index]=~EmailValidator::EMAIL_FORMAT
          cn = CertificateName.find_by_id(id)
          cn.domain_control_validations.create(dcv_method: "email", email_address: addresses[index])
          cnames << cn
        end
      end
      email_for_identifier = ''
      identifier = ''
      email_list = []
      identifier_list = []
      domain_ary = []
      domain_list = []
      cnames.each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv.email_address != email_for_identifier
          if domain_list.length>0
            domain_ary << domain_list
            email_list << email_for_identifier
            identifier_list << identifier
            domain_list = []
          end
          identifier = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
          email_for_identifier = dcv.email_address
        end
        domain_list << cn.name
        dcv.update_attribute(:identifier, identifier)
        dcv.send_dcv!
      end
      domain_ary << domain_list
      email_list << email_for_identifier
      identifier_list << identifier
      email_list.each_with_index do |value, key|
        OrderNotifier.dcv_email_send(nil, value, identifier_list[key], domain_ary[key], nil, @ssl_slug, 'group').deliver
      end
      flash[:notice] = "DCV email sent."
      redirect_to domains_path
    else
      @all_domains = []
      @address_choices = []
      params[:d_name_check].each do |dn_name_id|
        dn = CertificateName.find_by_id(dn_name_id)
        dcv = dn.domain_control_validations.last
        next if dcv && dcv.identifier_found
        @all_domains << dn
        standard_addresses = DomainControlValidation.email_address_choices(dn.name)
        whois_addresses = WhoisLookup.email_addresses(Whois.whois(ActionDispatch::Http::URL.extract_domain(dn.name, 1)).inspect)
        whois_addresses.each do |ad|
          standard_addresses << ad unless ad.include? 'abuse@'
        end
        @address_choices << standard_addresses
      end
    end
  end

  def select_csr
    if params[:d_name_check]
      @selected_domains = []
      params[:d_name_check].each do |d_id|
        dn = CertificateName.find_by_id(d_id)
        @selected_domains << dn
      end
      if @selected_domains.blank?
        redirect_to domains_path(@ssl_slug)
      end
      @csrs = current_user.ssl_account.csrs + current_user.ssl_account.managed_csrs
    else
      redirect_to domains_path(@ssl_slug)
    end
  end

  def validate_against_csr
    if params[:d_name_selected]
      @selected_domains = []
      @address_choices = []
      params[:d_name_selected].each do |d_id|
        dn = CertificateName.find_by_id(d_id)
        @selected_domains << dn
        standard_addresses = DomainControlValidation.email_address_choices(dn.name)
        whois_addresses = WhoisLookup.email_addresses(Whois.whois(ActionDispatch::Http::URL.extract_domain(dn.name, 1)).inspect)
        whois_addresses.each do |ad|
          standard_addresses << ad unless ad.include? 'abuse@'
        end
        if @selected_domains.blank?
          redirect_to domains_path(@ssl_slug)
        end
        @address_choices << standard_addresses
      end
      @csr = Csr.find_by_id(params[:selected_csr])
      if @csr.nil?
        redirect_to domains_path(@ssl_slug)
      end
      dcvs = @csr.csr_unique_value.domain_control_validations
      dcvs.each do |dcv|
        next if dcv.workflow_state == 'satisfied'
        dn = CertificateName.find_by_id(dcv.certificate_name_id)
        next if @selected_domains.include?(dn)
        @selected_domains << dn
        standard_addresses = DomainControlValidation.email_address_choices(dn.name)
        whois_addresses = WhoisLookup.email_addresses(Whois.whois(ActionDispatch::Http::URL.extract_domain(dn.name, 1)).inspect)
        whois_addresses.each do |ad|
          standard_addresses << ad unless ad.include? 'abuse@'
        end
        @address_choices << standard_addresses
      end
    elsif params[:unique_value]
      csr_unique_value = CsrUniqueValue.find_by_unique_value(params[:unique_value])
      @csr = csr_unique_value.csr
      dcvs = csr_unique_value.domain_control_validations
      @selected_domains = []
      @address_choices = []
      dcvs.each do |dcv|
        next if dcv.workflow_state == 'satisfied'
        dn = CertificateName.find_by_id(dcv.certificate_name_id)
        next if @selected_domains.include?(dn)
        @selected_domains << dn
        standard_addresses = DomainControlValidation.email_address_choices(dn.name)
        whois_addresses = WhoisLookup.email_addresses(Whois.whois(ActionDispatch::Http::URL.extract_domain(dn.name, 1)).inspect)
        whois_addresses.each do |ad|
          standard_addresses << ad unless ad.include? 'abuse@'
        end
        @address_choices << standard_addresses
      end
      if @selected_domains.blank?
        redirect_to domains_path(@ssl_slug)
      end
    else
      d_name_ids = params[:d_name_id]
      addresses = params[:dcv_address]
      @selected_domains = []
      @address_choices = []
      @csr = Csr.find_by_id(params[:selected_csr])
      cnames = []
      d_name_ids.each_with_index do |id, index|
        cn = CertificateName.find_by_id(id)
        @selected_domains << cn
        standard_addresses = DomainControlValidation.email_address_choices(cn.name)
        whois_addresses = WhoisLookup.email_addresses(Whois.whois(ActionDispatch::Http::URL.extract_domain(cn.name, 1)).inspect)
        whois_addresses.each do |ad|
          standard_addresses << ad unless ad.include? 'abuse@'
        end
        @address_choices << standard_addresses
        if addresses[index]=~EmailValidator::EMAIL_FORMAT
          cn.domain_control_validations.create(dcv_method: "email", email_address: addresses[index], csr_unique_value_id: @csr.csr_unique_value.id)
        elsif addresses[index] == 'http_csr_hash'
          cn.domain_control_validations.create(dcv_method: "http_csr_hash", failure_action: "ignore", csr_unique_value_id: @csr.csr_unique_value.id)
        elsif addresses[index] == 'https_csr_hash'
          cn.domain_control_validations.create(dcv_method: "https_csr_hash", failure_action: "ignore", csr_unique_value_id: @csr.csr_unique_value.id)
        elsif addresses[index] == 'cname_csr_hash'
          cn.domain_control_validations.create(dcv_method: "cname_csr_hash", failure_action: "ignore", csr_unique_value_id: @csr.csr_unique_value.id)
        else
          next
        end
        cnames << cn
      end
      email_for_identifier = ''
      identifier = ''
      email_list = []
      identifier_list = []
      domain_ary = []
      domain_list = []
      emailed_domains = []
      successed_domains = []
      failed_domains = []
      cnames.each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv.dcv_method == 'email'
          if dcv.email_address != email_for_identifier
            if domain_list.length>0
              domain_ary << domain_list
              email_list << email_for_identifier
              identifier_list << identifier
              domain_list = []
            end
            identifier = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
            email_for_identifier = dcv.email_address
          end
          domain_list << cn.name
          emailed_domains << cn.name
          dcv.update_attribute(:identifier, identifier)
          dcv.send_dcv!
        else
          if domain_verify(dcv.dcv_method, cn.name, @csr) == "true"
            successed_domains << cn.name
            dcv.satisfy! unless dcv.satisfied?
          else
            failed_domains << cn.name
          end
        end
      end
      domain_ary << domain_list
      email_list << email_for_identifier
      identifier_list << identifier
      unless domain_list.blank?
        email_list.each_with_index do |value, key|
          OrderNotifier.dcv_email_send(nil, value, identifier_list[key], domain_ary[key], nil, @ssl_slug, 'group').deliver
        end
      end
      notice_string = ""
      unless successed_domains.blank?
        notice_string += "DCV for #{successed_domains.join(", ")} successed. "
      end
      unless failed_domains.blank?
        notice_string += "DCV for #{failed_domains.join(", ")} failed. "
      end
      unless emailed_domains.blank?
        notice_string += "DCV email for #{emailed_domains.join(", ")} sent. "
      end
      flash[:notice] = notice_string
    end
  end

  def domain_verify(protocol, domain_name, csr)
    begin
      Timeout.timeout(Surl::TIMEOUT_DURATION) do
        if protocol=="https_csr_hash"
          url = "https://#{domain_name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          r = http.request(request).body
        elsif protocol=="cname_csr_hash"
          cname_destination = "#{csr.dns_sha2_hash}.com"
          txt = Resolv::DNS.open do |dns|
            cname_origin = "#{csr.dns_md5_hash}.#{domain_name}"
            records = dns.getresources(cname_origin, Resolv::DNS::Resource::IN::CNAME)
          end
          return cname_destination==txt.last.name.to_s
        else
          url = "http://#{domain_name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
          r=open(url, redirect: false).read
        end
        return "true" if !!(r =~ Regexp.new("^#{csr.sha2_hash}") && r =~ Regexp.new("^.com") &&
            (csr.unique_value.blank? ? true : r =~ Regexp.new("^#{csr.unique_value}")))
      end
    rescue Exception=>e
      return "false"
    end
  end

  def dcv_validate
    @domain = current_user.ssl_account.domains.find_by(id: params[:id])
    @domain = current_user.ssl_account.certificate_names.find_by(id: params[:id]) if @domain.nil?
    if(params['authenticity_token'])
      identifier = params['validate_code']
      dcv = @domain.domain_control_validations.last
      if dcv.identifier == identifier
        dcv.update_attribute(:identifier_found, true)
        dcv.satisfy! unless dcv.satisfied?
      end
    end
  end

  def dcv_all_validate
    dnames = current_user.ssl_account.domains
    cnames = current_user.ssl_account.certificate_names
    if(params['authenticity_token'])
      identifier = params['validate_code']
      cnames.each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv && dcv.identifier == identifier
          dcv.update_attribute(:identifier_found, true)
          dcv.satisfy! unless dcv.satisfied?
        end
      end
      dnames.each do |dn|
        dcv = dn.domain_control_validations.last
        if dcv && dcv.identifier == identifier
          dcv.update_attribute(:identifier_found, true)
          dcv.satisfy! unless dcv.satisfied?
        end
      end
    end
  end

  private
  def set_row_page
    @per_page = params[:per_page] ? params[:per_page] : 10
    CertificateName.per_page = @per_page if CertificateName.per_page != @per_page

    @p = {page: (params[:page] || 1), per_page: @per_page}
  end
end