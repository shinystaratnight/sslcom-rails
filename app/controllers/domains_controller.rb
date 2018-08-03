
class DomainsController < ApplicationController
  before_filter :require_user
  before_filter :find_ssl_account

  def index
    @cnames = @ssl_account.certificate_names.order(:created_at).reverse_order
    @domains = @ssl_account.domains.order(:created_at).reverse_order
  end

  def create
    exist_domain_names = []
    domain_names = params[:domain_names].split(/[\s,']/)
    domain_names.each do |d_name|
      if @ssl_account.domain_names.include?(d_name)
        exist_domain_names << d_name
      else
        @domain = Domain.new
        @domain.name = d_name
        @domain.ssl_account_id = @ssl_account.id
        @domain.save()
      end
    end
    if exist_domain_names.length > 0
      flash[:notice] = "#{exist_domain_names.join(', ')} #{exist_domain_names.length>1 ? "are" : "is"} already exist."
    end
    redirect_to domains_path(ssl_slug: @ssl_slug)
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
    if @domain.domain_control_validations.last.identifier_found
      redirect_to domains_path(@ssl_slug)
      return
    end
    @addresses = DomainControlValidation.email_address_choices(@domain.name)
    if params[:authenticity_token]
      if params[:dcv_address]=~EmailValidator::EMAIL_FORMAT
        identifier = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
        @domain.domain_control_validations.create(dcv_method: "email", email_address: params[:dcv_address],
                                                  identifier: identifier, failure_action: "ignore", candidate_addresses: @addresses)
        OrderNotifier.dcv_email_send(nil, params[:dcv_address], identifier, [@domain.name], @domain.id, @ssl_slug).deliver
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
      end
    end
  end
end