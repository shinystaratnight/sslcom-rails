class CertificateEnrollmentRequestsController < ApplicationController
  include OrdersHelper
  before_action :require_user, except: [:new, :create, :enrollment_links]
  before_action :find_request, only: [:reject, :destroy]
  before_action :find_ssl_account, only: [:new, :create, :enrollment_links]
  filter_access_to :all, except: [:new, :create, :enrollment_links]

  def index
    @requests = requests_base_query.joins(:certificate).sort_with(params)
    @requests = @requests.index_filter(params) if params[:commit]
    @requests = @requests.paginate(page: params[:page], per_page: 25)
  end

  def enrollment_links
    @certificates = Certificate.order(title: :asc).available.base_products
  end

  def new
    setup_request
  end

  def find_certificate
    find_by = if params[:product]
      { product: params[:product] }
    else
      { id: (params[:certificate_id] || params[:certificate_enrollment_request][:certificate_id]) }
    end
    @certificate = Certificate.find_by(find_by)
  end

  def create
    cer = params[:certificate_enrollment_request]
    @request = setup_request_create

    if @request.save
      team = @request.ssl_account
      (team.get_account_admins << team.get_account_owner).each do |team_admin|
        OrderNotifier.enrollment_request_for_team(team, @request, team_admin).deliver
      end

      target_path = if current_user && (current_user.is_owner? || current_user.is_account_admin?)
        certificate_enrollment_requests_path(cer[:ssl_slug])
      else
        enrollment_links_certificate_enrollment_requests_path(cer[:ssl_slug])
      end

      redirect_to target_path,
        notice: "Enrollment Request was successfully created."
    else
      render :new,
        error: "Failed to enroll due to errors, #{@request.errors.full_messages.join(', ')}."
    end
  end

  def reject
    @request.rejected!
    redirect_to :back, notice: "Enrollment Request was successfully rejected."
  end

  def destroy
    if @request and @request.destroy
      flash[:notice] = "Enrollment Request was successfully deleted."
    end
    redirect_to certificate_enrollment_requests_path(@ssl_slug)
  end

  private

  def setup_request
    find_certificate
    @ssl_slug = params[:ssl_slug]
    @duration = (params[:duration].to_i/365).to_i
    @request = CertificateEnrollmentRequest.new

    unless @certificate.blank?
      @certificate_order = CertificateOrder.new(
        duration: @duration,
        ssl_account: @ssl_account,
        has_csr: false
      )
      @certificate_content = CertificateContent.new(domains: [])
    end
  end

  def setup_request_create
    find_certificate
    cer = params[:certificate_enrollment_request]

    domains = cer[:signing_request] ? sslcom_request_domains : smime_client_parse_emails(cer[:domains])
    
    @request = CertificateEnrollmentRequest.new(
      domains: domains,
      certificate_id: cer[:certificate_id],
      ssl_account_id: @ssl_account.try(:id),
      duration: cer[:duration],
      server_software_id: cer[:server_software_id],
      signing_request: cer[:signing_request],
      status: CertificateEnrollmentRequest.statuses[:pending],
    )
  end
  
  def sslcom_request_domains
    cer = params[:certificate_enrollment_request]
    domains = [cer[:common_name].downcase]
    additional_domains = cer[:additional_domains]
    
    if additional_domains && !additional_domains.strip.blank?
      domains << additional_domains.strip.split(/[\s,]+/).map(&:strip).map(&:downcase)
    end
    domains.uniq
  end

  def find_ssl_account_by_slug
    @ssl_account = SslAccount.find_by(
      ssl_slug: ( params[:ssl_slug] || params[:certificate_enrollment_request][:ssl_slug] )
    )
  end
  
  def find_request
    @request = requests_base_query.find(params[:id])
  end
  
  def requests_base_query
    base = if current_user.is_system_admins?
      CertificateEnrollmentRequest.all
    else
      current_user.ssl_account.certificate_enrollment_requests
    end
  end
end
