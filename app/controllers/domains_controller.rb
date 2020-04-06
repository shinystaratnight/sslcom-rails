
class DomainsController < ApplicationController
  before_action :require_user, :except => [:dcv_validate, :dcv_all_validate]
  before_action :global_set_row_page, only: [:index, :search, :select_csr]
  before_action :find_ssl_account

  def search
    index
  end

  def index
    @search = params[:search] || ""

    if @search.blank?
      cnames = @ssl_account.all_certificate_names.includes(:domain_control_validations,:signed_certificates).order(created_at: :desc)
      total_domains = (@ssl_account.domains.order(created_at: :desc) + cnames).uniq(&:id)
    else
      cnames = @ssl_account.all_certificate_names.includes(:domain_control_validations,:signed_certificates).search_domains(params[:search])
      domains = @ssl_account.domains.search_domains(params[:search])
      total_domains = (domains + cnames).uniq(&:id)
    end

    @domains = total_domains.uniq{|cn| [cn.name, cn.certificate_content_id, cn.ssl_account_id]}.paginate(@p)

    respond_to do |format|
      format.html { render :action => :index }
      format.xml { render :xml => @domains }
    end
  end

  def create
    res_Obj = {}
    exist_domain_names = []
    created_domains = []
    created_domain_validated_status = {}
    validated_domains_remains = {}

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

          dcv = @domain.domain_control_validations.last
          created_domain_validated_status[d_name] = dcv && dcv.satisfied? ? 'true' : 'false'

          validated_domains_remains[d_name] = dcv && dcv.responded_at ?
                                                  DomainControlValidation::MAX_DURATION_DAYS[:email] - (Date.today - dcv.responded_at.to_date).to_i :
                                                  0
        end
      end
    end
    res_Obj['domains'] = created_domains
    res_Obj['domains_status'] = created_domain_validated_status
    res_Obj['remain_days'] = validated_domains_remains
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
    @addresses = CertificateName.candidate_email_addresses(@domain.non_wildcard_name)
    if params[:authenticity_token]
      if params[:dcv_address]=~EmailValidator::EMAIL_FORMAT
        if DomainControlValidation.approved_email_address? CertificateName.candidate_email_addresses(
            @domain.non_wildcard_name), params[:dcv_address]
          identifier = DomainControlValidation.generate_identifier
          @domain.domain_control_validations.create(dcv_method: "email", email_address: params[:dcv_address],
                                                    identifier: identifier, failure_action: "ignore", candidate_addresses: @addresses)
          OrderNotifier.dcv_email_send(params[:dcv_address], identifier, [@domain.name], @domain.id, @ssl_slug, 'team').deliver
          @domain.domain_control_validations.last.send_dcv!
          flash[:notice] = "Validation email has been sent."
        else
          flash[:notice] = "Invalid recipient email address."
        end
      end
    end
  end

  def validate_all
    if params[:authenticity_token]
      send_validation_email(params)
    end
    @all_domains = []
    @address_choices = []
    @cnames = @ssl_account.all_certificate_names(nil,"unvalidated").
        includes(:domain_control_validations).order(created_at: :desc)
    @cnames.each do |cn|
      dcv = cn.domain_control_validations.last
      next if dcv && dcv.identifier_found
      @all_domains << cn
      @address_choices << CertificateName.candidate_email_addresses(cn.non_wildcard_name)
    end
    @domains = @ssl_account.domains(nil,"unvalidated").includes(:domain_control_validations).order(created_at: :desc)
    @domains.each do |dn|
      dcv = dn.domain_control_validations.last
      next if dcv && dcv.identifier_found
      @all_domains << dn
      @address_choices << CertificateName.candidate_email_addresses(dn.non_wildcard_name)
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
        flash[:error] = "Please select a valid email address."
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
        @address_choices << CertificateName.candidate_email_addresses(dn.non_wildcard_name)

        @domain_details[dn.name] = {}
        @domain_details[dn.name]['dcv_method'] = dcv ? dcv.email_address : ''
        @domain_details[dn.name]['prev_attempt'] = dcv ? dcv.email_address : 'validation not performed yet'
        @domain_details[dn.name]['attempted_on'] = dcv ? dcv.created_at.strftime('%Y-%m-%d %H:%M:%S') : 'n/a'
        @domain_details[dn.name]['status'] = dcv ? 'pending' : 'waiting'
      end unless params[:d_name_check].blank?
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
        if @selected_domains.blank?
          redirect_to domains_path(@ssl_slug)
        end
        @address_choices << CertificateName.candidate_email_addresses(dn.non_wildcard_name)

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
      if @csr.blank?
        redirect_to domains_path(@ssl_slug)
      end
      dcvs = @csr.csr_unique_value.domain_control_validations
      dcvs.each do |dcv|
        next if dcv.workflow_state == 'satisfied'
        dn = CertificateName.find_by_id(dcv.certificate_name_id)
        next if @selected_domains.include?(dn)
        @selected_domains << dn
        @address_choices << CertificateName.candidate_email_addresses(dn.non_wildcard_name)

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
        @address_choices << CertificateName.candidate_email_addresses(dn.non_wildcard_name)

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
      dcvs=[]
      cn_ids = [] # need to touch certificate_names to bust cache since bulk insert skips callbacks
      d_name_ids.each_with_index do |id, index|
        cn = CertificateName.find_by_id(id)
        @selected_domains << cn
        @address_choices << CertificateName.candidate_email_addresses(cn.non_wildcard_name)
        if addresses[index]=~EmailValidator::EMAIL_FORMAT
          dcvs << cn.domain_control_validations.new(dcv_method: "email", email_address: addresses[index],
                                               candidate_addresses: @address_choices) if @address_choices.include?(addresses[index])
        elsif ['http_csr_hash','https_csr_hash','cname_csr_hash'].include? addresses[index]
          dcvs << cn.domain_control_validations.new(dcv_method: addresses[index], failure_action: "ignore",
                                                    csr_unique_value_id: @csr.csr_unique_value.id)
          cn_ids << id
        else
          next
        end
        cnames << cn
      end unless d_name_ids.blank?
      DomainControlValidation.import dcvs
      CertificateName.where(id: cn_ids).update_all updated_at: DateTime.now
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
          if DomainControlValidation.approved_email_address? CertificateName.candidate_email_addresses(
              cn.non_wildcard_name), dcv.email_address
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
            dcv.send_dcv! unless dcv.satisfied?
          end
        else
          if dcv_verify(dcv.dcv_method, cn.name, @csr)
            succeeded_domains << cn.name
            dcv.satisfy! unless dcv.satisfied?
          else
            failed_domains << cn.name
          end
        end
        dcv.save if dcv.new_record?
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
          OrderNotifier.dcv_email_send(value, identifier_list[key], domain_ary[key], nil, @ssl_slug, 'group').deliver
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
    @domain = current_user.ssl_account.domains.unvalidated.includes(:domain_control_validations).find_by(id: params[:id]) ||
        current_user.ssl_account.all_certificate_names(nil,"unvalidated").includes(:domain_control_validations).find_by(id: params[:id]) if @domain.nil?
    if(params['authenticity_token'])
      identifier = params['validate_code']
      dcv = @domain.domain_control_validations.last
      if dcv.validate(identifier)
        dcv.update_attribute(:identifier_found, true)
        unless dcv.satisfied?
          dcv.satisfy!
          # CaaCheck.pass?(@ssl_account.acct_number + 'domains', @domain, nil)
        end
      end
    end
  end

  def dcv_all_validate
    validated=[]
    # directly scoped to the team
    dnames = @ssl_account.domains.unvalidated.includes(:domain_control_validations)
    # scoped to certificate_orders
    cnames = @ssl_account.all_certificate_names(nil,"unvalidated").includes(:domain_control_validations)
    if(params['authenticity_token'])
      identifier = params['validate_code']
      attempt_to_issue=[]
      dcvs=[]
      cn_ids = [] # need to touch certificate_names to bust cache since bulk insert skips callbacks
      (dnames+cnames).each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv&.validate(identifier) && dcv&.responded_at.blank?
          validated << cn.name

          dcv.satisfy! unless dcv.satisfied?
          # find similar order scope domain (or create a new team scoped domain) and validate it
          team_domain=@ssl_account.domains.where.not(certificate_content_id: nil).find_by_name(cn.name) ||
              @ssl_account.domains.create(cn.attributes.except("id","certificate_content_id"))
          dcvs << team_domain.domain_control_validations.new(dcv.attributes.except("id")) if
                  team_domain.domain_control_validations.empty? or
                  !team_domain.domain_control_validations.last.satisfied?
          cn_ids << team_domain.id
          # find all other non validated certificate_names and validate them
          validated<<@ssl_account.satisfy_related_dcvs(cn)
          attempt_to_issue << cn.certificate_content.certificate_order if cn.certificate_content
        end
      end
      DomainControlValidation.import dcvs
      CertificateName.where(id: cn_ids).update_all updated_at: DateTime.now
      attempt_to_issue.uniq.compact.each{|co|co.apply_for_certificate}
      unless validated.empty?
        flash[:notice] = "The following domains are now validated: #{validated.flatten.uniq.join(" ,")}"
        redirect_to(domains_path) if current_user
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
        cn.domain_control_validations.create(dcv_method: "email", email_address: addresses[index],
                                   candidate_addresses: CertificateName.candidate_email_addresses(cn.non_wildcard_name))
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
      if DomainControlValidation.approved_email_address? CertificateName.candidate_email_addresses(
          cn.non_wildcard_name), dcv.email_address
        if dcv.email_address != email_for_identifier
          if domain_list.length > 0
            domain_ary << domain_list
            email_list << email_for_identifier
            identifier_list << identifier
            domain_list = []
          end
          identifier = DomainControlValidation.generate_identifier
          email_for_identifier = dcv.email_address
        end
        domain_list << cn.name
        dcv.update_attribute(:identifier, identifier)
        dcv.send_dcv!
      end
    end
    domain_ary << domain_list
    email_list << email_for_identifier
    identifier_list << identifier

    if email_list[0] != ''
      email_list.each_with_index do |value, key|
        OrderNotifier.dcv_email_send(value, identifier_list[key], domain_ary[key], nil, @ssl_slug, 'group').deliver
      end

      return true
    else
      return false
    end
  end

end
