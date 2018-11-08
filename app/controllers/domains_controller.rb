
class DomainsController < ApplicationController
  before_filter :require_user, :except => [:dcv_validate, :dcv_all_validate]
  before_filter :find_ssl_account
  before_filter :set_row_page, only: [:index]
  before_filter :set_csr_row_page, only: [:select_csr]

  def index
    cnames = @ssl_account.all_certificate_names.order(created_at: :desc)
    @domains = (@ssl_account.domains.order(created_at: :desc) + cnames).uniq(&:id).paginate(@p)
  end

  def create
    res_Obj = {}
    exist_domain_names = []
    created_domains = []
    unless params[:domain_names].nil?
      domain_names = params[:domain_names].split(/[\s,']/)
      domain_names.each do |d_name|
        next if d_name.empty?

        if @ssl_account.domains.map(&:name).include?(d_name)
          exist_domain_names << d_name
        else
          @domain = Domain.new
          @domain.name = d_name
          @domain.ssl_account_id = @ssl_account.id
          @domain.save()
          current_user.ssl_account.other_dcvs_satisfy_domain(@domain)
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
    @domain = current_user.ssl_account.all_certificate_names.find_by(id: params[:id]) if @domain.nil?
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
      send_validation_email(params)
    end
    @all_domains = []
    @address_choices = []
    @cnames = @ssl_account.all_certificate_names.order(created_at: :desc)
    @cnames.each do |cn|
      dcv = cn.domain_control_validations.last
      next if dcv && dcv.identifier_found
      @all_domains << cn
      @address_choices << DomainControlValidation.email_address_choices(cn.name)
    end
    @domains = @ssl_account.domains.order(created_at: :desc)
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
    if params[:d_name_id]
      is_sent = send_validation_email(params)

      if is_sent
        flash[:notice] = "Please check your email for the validation code and submit it below to complete validation."
      else
        flash[:error] = "You have not choose validation email address for all domains."
      end

      @validation_url = dcv_all_validate_domains_url(params)
      redirect_to dcv_all_validate_domains_url(ssl_slug: current_user.ssl_account.ssl_slug)
    else
      @all_domains = []
      @address_choices = []
      @domain_details = {}
      params[:d_name_check].each do |dn_name_id|
        dn = CertificateName.find_by_id(dn_name_id)
        dcv = dn.domain_control_validations.last
        next if dcv && dcv.identifier_found
        @all_domains << dn
        standard_addresses = DomainControlValidation.email_address_choices(dn.name)
        begin
          whois_addresses = WhoisLookup.email_addresses(Whois.whois(ActionDispatch::Http::URL.extract_domain(dn.name, 1)).inspect)
          whois_addresses.each do |ad|
            standard_addresses << ad unless ad.include? 'abuse@'
          end
        rescue Exception=>e
          logger.error e.backtrace.inspect
        end
        @address_choices << standard_addresses

        @domain_details[dn.name] = {}
        @domain_details[dn.name]['dcv_method'] = dcv ? dcv.email_address : ''
        @domain_details[dn.name]['prev_attempt'] = dcv ? dcv.email_address : 'validation not performed yet'
        @domain_details[dn.name]['attempted_on'] = dcv ? dcv.created_at.strftime('%Y-%m-%d %H:%M:%S') : 'n/a'
        @domain_details[dn.name]['status'] = dcv ? 'pending' : 'waiting'
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
      @csrs = current_user.ssl_account.all_csrs.paginate(@p)
    else
      redirect_to domains_path(@ssl_slug)
    end
  end

  def validate_against_csr
    if params[:authenticity_token] && params[:d_name_selected]
      @selected_domains = []
      @address_choices = []
      @domain_details = {}
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

        @domain_details[dn.name] = {}
        dcv_last = dn.domain_control_validations.last
        @domain_details[dn.name]['dcv_method'] = dcv_last ?
                       (dcv_last.email_address ?
                            dcv_last.email_address
                            : dcv_last.dcv_method)
                       : ''
        @domain_details[dn.name]['prev_attempt'] = dcv_last ?
                       (dcv_last.satisfied? ?
                            'validated' :
                            (dcv_last.email_address ?
                                 dcv_last.email_address
                                 : dcv_last.dcv_method))
                       : 'validation not performed yet'
        @domain_details[dn.name]['attempted_on'] = dcv_last ? dcv_last.created_at : 'n/a'
        @domain_details[dn.name]['status'] = dcv_last ? (dcv_last.satisfied? ? 'satisfied' : 'pending') : 'waiting'
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

        @domain_details[dn.name] = {}
        dcv_last = dn.domain_control_validations.last
        @domain_details[dn.name]['dcv_method'] = dcv_last ?
                                                     (dcv_last.email_address ?
                                                          dcv_last.email_address
                                                          : dcv_last.dcv_method)
                                                     : ''
        @domain_details[dn.name]['prev_attempt'] = dcv_last ?
                                                       (dcv_last.satisfied? ?
                                                            'validated' :
                                                            (dcv_last.email_address ?
                                                                 dcv_last.email_address
                                                                 : dcv_last.dcv_method))
                                                       : 'validation not performed yet'
        @domain_details[dn.name]['attempted_on'] = dcv_last ? dcv_last.created_at.strftime('%Y-%m-%d %H:%M:%S') : 'n/a'
        @domain_details[dn.name]['status'] = dcv_last ? (dcv_last.satisfied? ? 'satisfied' : 'pending') : 'waiting'
      end
    elsif !params[:authenticity_token] && params[:unique_value]
      csr_unique_value = CsrUniqueValue.find_by_unique_value(params[:unique_value])
      @csr = csr_unique_value.csr
      dcvs = csr_unique_value.domain_control_validations

      @selected_domains = []
      @address_choices = []
      @domain_details = {}

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

        @domain_details[dn.name] = {}
        dcv_last = dn.domain_control_validations.last
        @domain_details[dn.name]['dcv_method'] = dcv_last ?
                                                     (dcv_last.email_address ?
                                                          dcv_last.email_address
                                                          : dcv_last.dcv_method)
                                                     : ''
        @domain_details[dn.name]['prev_attempt'] = dcv_last ?
                                                       (dcv_last.satisfied? ?
                                                            'validated' :
                                                            (dcv_last.email_address ?
                                                                 dcv_last.email_address
                                                                 : dcv_last.dcv_method))
                                                       : 'validation not performed yet'
        @domain_details[dn.name]['attempted_on'] = dcv_last ? dcv_last.created_at.strftime('%Y-%m-%d %H:%M:%S') : 'n/a'
        @domain_details[dn.name]['status'] = dcv_last ? (dcv_last.satisfied? ? 'satisfied' : 'pending') : 'waiting'
      end
      if @selected_domains.blank?
        redirect_to domains_path(@ssl_slug)
      end
    else
      d_name_ids = params[:d_name_id]
      addresses = params[:dcv_address]
      @selected_domains = []
      @address_choices = []
      @domain_details = {}
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
      succeeded_domains = []
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
          if dcv_verify(dcv.dcv_method, cn.name, @csr)
            succeeded_domains << cn.name
            dcv.satisfy! unless dcv.satisfied?
          else
            failed_domains << cn.name
          end
        end

        @domain_details[cn.name] = {}
        @domain_details[cn.name]['dcv_method'] = dcv ?
                                                     (dcv.email_address ?
                                                          dcv.email_address
                                                          : dcv.dcv_method)
                                                     : ''
        @domain_details[cn.name]['prev_attempt'] = dcv ?
                                                       (dcv.satisfied? ?
                                                            'validated' :
                                                            (dcv.email_address ?
                                                                 dcv.email_address
                                                                 : dcv.dcv_method))
                                                       : 'validation not performed yet'
        @domain_details[cn.name]['attempted_on'] = dcv ? dcv.created_at.strftime('%Y-%m-%d %H:%M:%S') : 'n/a'
        @domain_details[cn.name]['status'] = dcv ? (dcv.satisfied? ? 'satisfied' : 'pending') : 'waiting'
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
      unless succeeded_domains.blank?
        notice_string += "Domain Control Validation for #{succeeded_domains.join(", ")} succeeded. "
      end
      unless failed_domains.blank?
        notice_string += "Domain Control Validation for #{failed_domains.join(", ")} failed. "
      end
      unless emailed_domains.blank?
        notice_string += "Domain Control Validation email for #{emailed_domains.join(", ")} sent. "
      end
      flash[:notice] = notice_string
    end
  end

  def dcv_verify(protocol, domain_name, csr)
    CertificateName.dcv_verify(protocol: protocol,
                               https_dcv_url: "https://#{domain_name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
                               http_dcv_url: "http://#{domain_name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
                               cname_origin: "#{csr.dns_md5_hash}.#{domain_name}",
                               cname_destination: "#{csr.cname_destination}",
                               csr: csr,
                               ca_tag: csr.ca_tag)
  end

  def dcv_validate
    @domain = current_user.ssl_account.domains.find_by(id: params[:id]) ||
        current_user.ssl_account.all_certificate_names.find_by(id: params[:id]) if @domain.nil?
    if(params['authenticity_token'])
      identifier = params['validate_code']
      dcv = @domain.domain_control_validations.last
      if dcv.identifier == identifier
        dcv.update_attribute(:identifier_found, true)
        unless dcv.satisfied?
          dcv.satisfy!
          CaaCheck.pass?(@ssl_account.acct_number + 'domains', @domain, nil)
        end
      end
    end
  end

  def dcv_all_validate
    validated=[]
    dnames = @ssl_account.domains # directly scoped to the team
    cnames = @ssl_account.all_certificate_names # scoped to certificate_orders
    if(params['authenticity_token'])
      identifier = params['validate_code']
      (dnames+cnames).each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv && dcv.identifier == identifier && dcv.responded_at.blank?
          # dcv.update_columns(identifier_found: true, responded_at: DateTime.now)
          validated << cn.name
          unless dcv.satisfied?
            dcv.satisfy!
            cn.certificate_order.apply_for_certificate
            # CaaCheck.pass?(@ssl_account.acct_number + 'domains', cn, nil)
          end
          # find similar order scope domain (or create a new team scoped domain) and validate it
          team_domain=@ssl_account.domains.where.not(certificate_content_id: nil).find_by_name(cn.name) ||
              @ssl_account.domains.create(cn.attributes.except("id","certificate_content_id"))
          team_domain.domain_control_validations.create(dcv.attributes.except("id")) if
                  team_domain.domain_control_validations.empty? or
                  !team_domain.domain_control_validations.last.satisfied?
          # find all other non validated certificate_names and validate them
          validated<<@ssl_account.satisfy_related_dcvs(cn)
        end
      end
      unless validated.empty?
        flash[:notice] = "The following are now validated: #{validated.flatten.join(" ,")}"
        redirect_to domains_path
      else
        flash.now[:error] = "No domains have been validated."
      end
    end
  end

  private

  def send_validation_email(params)
    d_name_ids = params[:d_name_id]
    addresses = params[:dcv_address]
    cnames = []
    d_name_ids.each_with_index do |id, index|
      if addresses[index] =~ EmailValidator::EMAIL_FORMAT
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
        if domain_list.length > 0
          domain_ary << domain_list
          email_list << email_for_identifier
          identifier_list << identifier
          domain_list = []
        end
        identifier = (SecureRandom.hex(8) + Time.now.to_i.to_s(32))[0..19]
        email_for_identifier = dcv.email_address
      end
      domain_list << cn.name
      dcv.update_attribute(:identifier, identifier)
      dcv.send_dcv!
    end
    domain_ary << domain_list
    email_list << email_for_identifier
    identifier_list << identifier

    if email_list[0] != ''
      email_list.each_with_index do |value, key|
        OrderNotifier.dcv_email_send(nil, value, identifier_list[key], domain_ary[key], nil, @ssl_slug, 'group').deliver
      end

      return true
    else
      return false
    end
  end

  def set_row_page
    preferred_row_count = current_user.preferred_domain_row_count
    @per_page = params[:per_page] || preferred_row_count.or_else("10")
    Domain.per_page = @per_page if Domain.per_page != @per_page

    if @per_page != preferred_row_count
      current_user.preferred_domain_row_count = @per_page
      current_user.save(validate: false)
    end

    @p = {page: (params[:page] || 1), per_page: @per_page}
  end

  def set_csr_row_page
    preferred_row_count = current_user.preferred_domain_csr_row_count
    @per_page = params[:per_page] || preferred_row_count.or_else("10")
    Domain.csr_per_page = @per_page if Domain.csr_per_page != @per_page

    if @per_page != preferred_row_count
      current_user.preferred_domain_csr_row_count = @per_page
      current_user.save(validate: false)
    end

    @p = {page: (params[:page] || 1), per_page: @per_page}
  end
end