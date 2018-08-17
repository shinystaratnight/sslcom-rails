
class DomainsController < ApplicationController
  before_filter :require_user, :except => [:dcv_validate, :dcv_all_validate]
  before_filter :find_ssl_account

  def index
    @cnames = @ssl_account.certificate_names.order(:created_at).reverse_order
    @domains = @ssl_account.domains.order(:created_at).reverse_order
  end

  def create
    res_Obj = {}
    exist_domain_names = []
    created_domains = []
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
    params[:d_name_check].each do |d_name_id|
      d_name = CertificateName.find_by_id(d_name_id)
      d_name.destroy
    end
    flash[:notice] = "Domain was successfully deleted."
    redirect_to domains_path(@ssl_slug)
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
          standard_addresses << ad unless ad.include? 'abuse'
        end
        @address_choices << standard_addresses
      end
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
end