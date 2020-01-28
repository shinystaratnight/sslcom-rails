#ordering a certificate can be convoluted process because we wanted to maximize seo in the url and not
#necessarily follow proper REST. the flow is as follows:
#CertificatesController#buy
#OrdersController#new
#(or CertificateOrdersController#update_csr if unused credit)
#FundedAccount#allocate_funds or #confirm_funds if from funded_account (ie reseller)
#OrdersController#create_multi_free_ssl or OrdersController#create_free_ssl
#CertificateOrdersController#edit (goes to application info prompt) or OrdersController#edit or OrdersController#new
#CertificateOrdersController#update (goes to provide contacts prompt)
#CertificateContentsController#update if not express
#ValidationsController#new (asks for validation dcv and docs if not intranet/ucc, otherwise completes order)
#ValidationsController#upload
#
#order is sent to api in the pend_validation workflow transition in certificate_content
#OrderNotifier views contain all the email sent to customer during order

class CertificateOrdersController < ApplicationController
  layout 'application'
  include OrdersHelper
  include CertificateOrdersHelper

  skip_before_action :verify_authenticity_token, only: [:parse_csr]
  filter_access_to :all, except: [:generate_cert]
  filter_access_to :read, :update, :delete, :show, :edit, :developer, :recipient
  filter_access_to :incomplete, :pending, :search, :reprocessing, :order_by_csr, :require=>:read
  filter_access_to :credits, :filter_by, :filter_by_scope, :require=>:index
  filter_access_to :update_csr, :generate_cert, require: [:update]
  filter_access_to :download, :download_certificates, :start_over, :reprocess, :admin_update, :change_ext_order_number, :switch_from_comodo,
                   :developers, :require=>[:update, :delete]
  filter_access_to :renew, :parse_csr, require: [:create]
  filter_access_to :auto_renew, require: [:admin_manage]
  filter_access_to :show_cert_order, :validate_issue, :register_domains, :save_attestation, :remove_attestation, :require=>:ajax
  before_filter :find_certificate, only: [:enrollment]
  before_filter :load_certificate_order,
                only: [:show, :show_cert_order, :validate_issue, :update, :edit, :download, :destroy, :delete, :update_csr, :auto_renew, :start_over,
                       :change_ext_order_number, :admin_update, :developer, :sslcom_ca, :update_tags, :recipient, :validate_issue, :attestation,
                        :save_attestation, :remove_attestation]
  before_filter :global_set_row_page, only: [:index, :search, :credits, :pending, :filter_by_scope, :order_by_csr, :filter_by,
                                             :incomplete, :reprocessing]
  before_filter :get_team_tags, only: [:index, :search]
  before_filter :construct_special_fields, only: [:edit, :create, :update, :update_csr]
  in_place_edit_for :certificate_order, :notes
  in_place_edit_for :csr, :signed_certificate_by_text

  before_action :set_schedule_value, only: [:edit, :reprocess]
  before_action :set_algorithm_and_size, only: [:generate_cert]

  NUM_ROWS_LIMIT=2

  def smime_client_enrollment
    if params[:get_duration]
      render_certificate_durations
    elsif params[:smime_client_create]
      smime_client_create
    else
      smime_client_init
    end
  end

  def update_tags
    if @certificate_order
      @taggable = @certificate_order
      get_team_tags
      Tag.update_for_model(@taggable, params[:tags_list])
    end
    render json: {
      tags_list: @taggable.nil? ? [] : @taggable.tags.pluck(:name)
    }
  end

  def generate_cert
    co_token = CertificateOrderToken.find_by_token(params[:token])
    if co_token.user.blank? and co_token.certificate_order.get_download_cert_email==current_user.try(:email) and
        Settings.require_login_smime_claim==true
      co_token.update_column :user_id, current_user.id
    end
    is_expired = false

    if co_token
      if co_token.user != current_user and Settings.require_login_smime_claim==true
        is_expired = true
        flash[:error] = "Access to this page is denied. Please log in as the user assigned to this token."
      elsif co_token.is_expired
        is_expired = true
        flash[:error] = "The page has expired or is no longer valid."
      # elsif co_token.due_date < DateTime.now
      #   is_expired = true
      #   # co_token.update_attribute(:is_expired, true)
      #
      #   flash[:error] = "The page has expired or is no longer valid."
      else
        @certificate_order = co_token.certificate_order
        @token = params[:token]
        @managed_csr = Csr.find_by_ref(params[:csr_ref]) unless params[:csr_ref].blank?
      end
    else
      is_expired = true
      flash[:error] = "Provided token is incorrect."
    end

    if is_expired
      render "confirm"
    else
      render "generate_cert"
    end
  end

  def show_cert_order
    if current_user
      render :partial=>'detailed_info', :locals=>{:certificate_order=>@certificate_order}
    else
      render :json => 'no-user'
    end
  end

  def search
    index
  end

  # GET /certificate_orders
  # GET /certificate_orders.xml
  def index

    @certificate_orders = find_certificate_orders.paginate(@p)

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/1
  # GET /certificate_orders/1.xml
  def show
    if @certificate_order.workflow_state=="refunded"
      not_found
    else
      @taggable = @certificate_order
      get_team_tags
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order) and return if @certificate_order.certificate_content && @certificate_order.certificate_content.new?
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @certificate_order }
      end
    end
  end

  def validate_issue
    cc = @certificate_order.certificate_content
    @certificate_order.apply_for_certificate(
        mapping: cc.ca,
        current_user: current_user
    ) unless cc.preferred_pending_issuance?
    render :json => cc.issued?
  end

  def auto_renew
    action = CertificateOrder::RENEWING
    iv = recert(action)
    unless iv.blank?
      redirect_to buy_certificate_url(iv.renewal_certificate,
        {action.to_sym=>params[:id]})
    else
      not_found
    end
  end

  def sslcom_ca

  end

  def renew
    action = CertificateOrder::RENEWING
    iv = recert(action)
    unless iv.blank?
      redirect_to buy_renewal_certificate_url(iv.renewal_certificate,
        {action.to_sym=>params[:id]})
    else
      not_found
    end
  end

  # GET /certificate_orders/1/edit

  def edit
    unless @certificate_order.blank?
      if @certificate_order.certificate_content.ca.blank?
        cc=@certificate_order.certificate_content
        cc.add_ca(@certificate_order.ssl_account) if @certificate_order.external_order_number.blank?
        cc.save
      end
      if (@certificate_order.certificate.is_client_pro? || @certificate_order.certificate.is_client_basic?) &&
          !@certificate_order.certificate_content.validated?
        redirect_to recipient_certificate_order_path(@ssl_slug, @certificate_order.ref)
      else
        @certificate = @certificate_order.mapped_certificate

        unless @certificate.admin_submit_csr?

          if @certificate_order.is_unused_credit?
            @certificate_order.has_csr=true
            @certificate_content = @certificate_order.certificate_content
            @certificate_content.agreement=true

            # @notification_groups = @certificate_order.ssl_account.notification_groups.pluck(:friendly_name, :ref)
            @notification_groups = @certificate_order.ssl_account.cached_notification_groups.pluck(:friendly_name, :ref)
            @notification_groups.insert(0, ['none', 'none']) if @notification_groups.empty?

            @managed_csrs = (@certificate_order.ssl_account.all_csrs)
                                .sort_by{|arr| arr.try(:common_name) || ""}
                                .map{|arr| [(arr.friendly_name || arr.try(:common_name) || "")+' '+ arr.public_key_sha1,
                                            arr.ref]}
                                .delete_if{|arr| arr.second == nil}
            @managed_csrs.insert(0, ['none', 'none'])

            if params[:csr_ref]
              @generated_csr = params[:csr_ref]
            end

            @is_reprocess = false

            return render 'submit_csr', :layout=>'application'
          end
          unless @certificate_order.certificate_content.csr_submitted? or params[:registrant]
            redirect_to certificate_order_path(@ssl_slug, @certificate_order)
          else
            @csr = @certificate_order.certificate_content.csr
            registrants_on_edit
          end
        else
          registrants_on_edit
        end
        @saved_registrants = @certificate_order.ssl_account.saved_registrants
      end

      unless params[:approve_phone].blank?
        flash[:notice] = "It needs to verify phone number."
      end
    else
      not_found
    end
  end

  # GET /certificate_orders/1/reprocess
  def reprocess
    @certificate_order = recert(CertificateOrder::REPROCESSING)
    @certificate_order.unchain_comodo if @certificate_order.signed_certificate_duration_delta > 1
    @tier = find_tier
    unless @certificate_order.blank?
      if @certificate_order.certificate_content.workflow_state == 'pending_validation' &&
        !current_user.is_system_admins?
        redirect_to new_certificate_order_validation_path(@ssl_slug, @certificate_order)
      else
        @certificate_order.has_csr=true
        @certificate = @certificate_order.mapped_certificate
        @certificate_content = @certificate_order.certificate_contents.build(
          domains: @certificate_order.certificate_content.signed_certificate.try(:subject_alternative_names),
          server_software_id: @certificate_order.certificate_content.server_software_id
        )
        # @certificate_content.additional_domains = domains
        #reset dcv validation
        @certificate_content.add_ca(@certificate_order.ssl_account) if @certificate_order.external_order_number.blank?
        @certificate_content.agreement=true
        @certificate_order.validation.validation_rules.each do |vr|
          if vr.description=~/\Adomain/
            ruling=@certificate_order.validation.validation_rulings.detect{|vrl| vrl.validation_rule == vr}
            ruling.pend! unless ruling.pending?
          end
        end

        # @notification_groups = current_user.ssl_account.notification_groups.pluck(:friendly_name, :ref)
        @notification_groups = current_user.ssl_account.cached_notification_groups.pluck(:friendly_name, :ref)
        @notification_groups.insert(0, ['none', 'none']) #if @notification_groups.empty?

        notification_group_subject = @certificate_order.notification_groups_subjects.where(created_page: 'csr').first
        @slt_notification_group = [notification_group_subject.notification_group.ref] if notification_group_subject

        @managed_csrs = (@certificate_order.ssl_account.all_csrs)
                            .sort_by{|arr| arr.common_name || ""}
                            .map{|arr| [(arr.friendly_name || arr.common_name || "")+' '+ arr.public_key_sha1, arr.ref]}
                            .delete_if{|arr| arr.second == nil}
        @managed_csrs.insert(0, ['none', 'none'])

        if params[:csr_ref]
          @generated_csr = params[:csr_ref]
        end

        @is_reprocess = true

        return render 'submit_csr', :layout=>'application'
      end
    else
      not_found
    end
  end

  # POST /certificate_orders
  # POST /certificate_orders.xml
  def create
    redirect_to new_order_url and return unless current_user
    certificate_order = CertificateOrder.new(params[:certificate_order])
    @certificate = Certificate.for_sale.find_by_product(params[:certificate][:product])
    determine_eligibility_to_buy(@certificate, certificate_order)
    @certificate_order = Order.setup_certificate_order(certificate: @certificate, certificate_order: certificate_order)
    respond_to do |format|
      if @certificate_order.save
        if is_reseller? && (current_order.amount.cents >
              current_user.ssl_account.funded_account.amount.cents)
          format.html {redirect_to allocate_funds_for_order_path(:id=>
                'certificate')}
        else
          format.html {redirect_to confirm_funds_path(:id=>'certificate_order')}
        end
      else
        format.html { render(:template => "submit_csr")}
      end
    end
  end

  # PUT /certificate_orders/1
  # PUT /certificate_orders/1.xml
  def update
    respond_to do |format|
      params[:certificate_order][:certificate_contents_attributes]['0'][:registrant_attributes][:country_code] =
          params[:country_code] if params[:country_code]

      is_smime_or_client = @certificate_order.certificate.is_smime_or_client?
      if @certificate_order.update_attributes(params[:certificate_order])
        cc = @certificate_order.certificate_content
        original_state_phone_approve = cc.locked_registrant.blank? ? false : cc.locked_registrant.phone_number_approved

        # TODO: Store LockedRegistrant Data in case of CS
        setup_locked_registrant(
          params[:certificate_order][:certificate_contents_attributes]['0'], cc
        ) if @certificate_order.certificate.requires_locked_registrant?

        setup_reusable_registrant(@certificate_order.registrant) if params[:save_for_later]

        if cc.csr_submitted? or cc.new?
          cc.provide_info!
          if current_user.ssl_account.is_registered_reseller?
            @order = @certificate_order.order
            unless @order.deducted_from.blank?
              @deposit = @order.deducted_from
              @profile = @deposit.billing_profile
            end
            unless is_smime_or_client
              CertificateContent::CONTACT_ROLES.each do |role|
                c = CertificateContact.new
                r = current_user.ssl_account.reseller
                CertificateContent::RESELLER_FIELDS_TO_COPY.each do |field|
                  c.send((field+'=').to_sym, r.send(field.to_sym))
                end
                c.company_name = r.organization
                c.country = Country.find_by_name_caps(r.country.upcase).iso1_code if
                    Country.find_by_name_caps(r.country.upcase)
                c.clear_roles
                c.add_role! role
                cc.certificate_contacts << c
                cc.update_attribute(role+"_checkbox", true) unless
                  role==CertificateContent::ADMINISTRATIVE_ROLE
              end
            else

            end
            unless @certificate_order.certificate.is_ev?
              cc.provide_contacts!
            end
          end
        end

        if current_user.is_super_user? && !original_state_phone_approve &&
            !params[:certificate_order][:certificate_contents_attributes]['0'][:registrant_attributes][:phone].blank? &&
            !params[:certificate_order][:certificate_contents_attributes]['0'][:registrant_attributes][:phone_number_approved].blank? &&
            params[:certificate_order][:certificate_contents_attributes]['0'][:registrant_attributes][:phone_number_approved] == '1'
          OrderNotifier.notify_phone_number_approve(@certificate_order, current_user.email).deliver
          flash[:notice] = "Phone number approved and notification sent to this certificate order's owner."
        end

        if is_smime_or_client
          format.html { redirect_to recipient_certificate_order_path(@ssl_slug, @certificate_order.ref) }
        elsif @certificate_order.express_signup? || @certificate_order.skip_contacts_step?
          format.html { redirect_to validation_destination(slug: @ssl_slug, certificate_order: @certificate_order) }
        else #assume ev full signup process
          format.html { redirect_to certificate_content_contacts_path(@ssl_slug, cc) }
        end
        format.xml  { head :ok }
      else
        setup_registrant(
          params[:certificate_order][:certificate_contents_attributes]['0'][:registrant_attributes]
        )
        format.html { render 'edit' }
        format.xml  { render :xml => @certificate_order.errors, :status => :unprocessable_entity }
      end
    end
  end

  def recipient
    @assignee_id = nil
    @iv_exists = nil
    edit_locked_recipient = current_user.is_system_admins? && (params[:edit_locked_recipient] == 'true')

    if params[:add_recipient] == 'true'
      find_team_iv

      if @assignee_id && !edit_locked_recipient
        @certificate_order.update_column(:assignee_id, @assignee_id)
      else
        invite_recipient
      end

      if @iv_exists && @iv_exists.persisted?
        if @certificate_order.locked_recipient.nil? || edit_locked_recipient
          for_assignee = edit_locked_recipient ? @iv_exists.user_id : nil
          LockedRecipient.create_for_co(@certificate_order, for_assignee)
        end
        edit_locked_recipient ? update_recipient(:locked) : update_recipient
        # Local Registration Authority, validate IV
        @iv_exists.update_column(:status, Contact::statuses[:validated]) if params[:lra]
      end

      if @iv_exists.nil? && @assignee_id.nil?
        redirect_to :back, error: 'Something went wrong, please try again'
      else
        client_smime_validate
      end
    else
      render :recipient
    end
  end

  # PUT /certificate_orders/1
  # PUT /certificate_orders/1.xml
  def update_csr
    if Settings.csr_domains_ui
      managed_domains = params[:managed_domains]
      additional_domains = ''
      managed_domains.each do |domain|
        additional_domains.concat(domain.gsub('csr-', '') + ' ')
      end unless managed_domains.blank?

      params[:certificate_order][:certificate_contents_attributes]['0'.to_sym][:additional_domains] = additional_domains.strip
    end

    if @certificate_order.certificate.is_single?
      params[:certificate_order][:certificate_contents_attributes]['0'.to_sym][:additional_domains]=[]
    elsif @certificate_order.certificate.is_premium_ssl?
      params[:certificate_order][:certificate_contents_attributes]['0'.to_sym][:additional_domains]=
          params[:certificate_order][:certificate_contents_attributes]['0'.to_sym][:additional_domains].
              split(Certificate::DOMAINS_TEXTAREA_SEPARATOR)[0..2].join(" ")
    end

    @certificate_content=CertificateContent.new(
      params[:certificate_order][:certificate_contents_attributes]['0'.to_sym]
        .merge(rekey_certificate: true)
    )
    @certificate_order.has_csr=true #we are submitting a csr afterall
    @certificate_content.certificate_order=@certificate_order
    @certificate_content.preferred_reprocessing=true if eval("@#{CertificateOrder::REPROCESSING}")

    da_billing     = @certificate_order.domains_adjust_billing?
    ucc_renew      = true if da_billing && @certificate_order.renew_billing?
    ucc_reprocess  = true if da_billing && !params[:reprocessing].blank?
    ucc_csr_submit = true if da_billing && !ucc_reprocess && !ucc_renew
    domains_adjustment = ucc_reprocess || ucc_renew || ucc_csr_submit

    respond_to do |format|
      if @certificate_content.valid?
        cc = @certificate_order.transfer_certificate_content(@certificate_content)

        if params[:common_name] && !params[:common_name].empty? && PublicSuffix.valid?(params[:common_name])
          if @certificate_order.certificate.is_single? or @certificate_order.certificate.is_wildcard?
            cert_single_name = cc.certificate_names.where(is_common_name: true).first

            if cert_single_name and cert_single_name.name.downcase != params[:common_name].downcase
              cert_single_name.update_column(:name,
                                   CertificateContent.non_wildcard_name(params[:common_name].downcase,false))
              cert_single_name.domain_control_validations.delete_all # remove any previous validations
              cert_single_name.candidate_email_addresses # start the queued job running
              Delayed::Job.enqueue CertificateContent::OtherDcvsSatisyJob.new(@certificate_order.ssl_account,
                                cert_single_name,cc,"dv_only") if @certificate_order.ssl_account &&
                                                                @certificate_order.certificate.is_server?
              # Basic and High Assurance includes domain minus www
              if CertificateContent.non_wildcard_name(params[:common_name].downcase,true) != cert_single_name.name
                no_www=cc.certificate_names.create(is_common_name: false, name:
                                   CertificateContent.non_wildcard_name(params[:common_name].downcase,true))
                no_www.candidate_email_addresses # start the queued job running
                Delayed::Job.enqueue CertificateContent::OtherDcvsSatisyJob.new(@certificate_order.ssl_account,
                                no_www,cc,"dv_only") if @certificate_order.ssl_account &&
                                                      @certificate_order.certificate.is_server?
              end
            end
          else
            domains = cc.domains
            unless domains.include? params[:common_name]
              domains << params[:common_name]
              cc.update_attribute(:domains, domains.join(' '))
            end

            common_name_domain = cc.certificate_names.where(is_common_name: true).first
            common_name_domain.update_attribute(:is_common_name, false) if common_name_domain
            cc.certificate_names.find_by_name(params[:common_name]).update_attribute(:is_common_name, true)
          end
        end

        if domains_adjustment
          o = params[:order]
          order_params = {
            co_ref:            @certificate_order.ref,
            cc_ref:             cc.ref,
            reprocess_ucc:      ucc_reprocess,
            renew_ucc:          ucc_renew,
            ucc_csr_submit:     ucc_csr_submit,
            wildcard_amount:    o[:wildcard_amount],
            nonwildcard_amount: o[:nonwildcard_amount],
            order_description:  o[:order_description],
            order_amount:       o[:adjustment_amount],
            wildcard_count:     o[:wildcard_count].to_i,
            nonwildcard_count:  o[:nonwildcard_count].to_i
          }

          # setting managed_csr and domains.
          setup_managed_csr_domains(params)

          # scheduling
          schedule(params)

          format.html { redirect_to new_order_path(@ssl_slug, order_params) }
        else
          if cc.pending_validation?
            format.html { redirect_to certificate_order_path(@ssl_slug, @certificate_order) }
          end

          # setting managed_csr and domains.
          setup_managed_csr_domains(params)

          # scheduling
          schedule(params)

          format.html { redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order) }
          format.xml  { head :ok }
        end
      else
        if domains_adjustment
          path = if ucc_reprocess
            reprocess_certificate_order_path(@ssl_slug, @certificate_order)
          else
            edit_certificate_order_path(@ssl_slug, @certificate_order)
          end
          #Confirm this change to see if its breaking or not.
          @certificate = @certificate_order.certificate
          format.html { render 'submit_csr', layout: 'application' }
        else
          @certificate = @certificate_order.certificate
          format.html { render 'submit_csr', layout: 'application' }
          format.xml  { render xml: @certificate_order.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def change_ext_order_number
    if params[:num].blank?
      @certificate_order.unchain_comodo
    else
      @certificate_order.update_column :external_order_number, params[:num]
      @certificate_order.certificate_contents.last.update_column :ca_id, nil
    end
    SystemAudit.create(owner: current_user, target: @certificate_order,
                       action: "changed external order number to #{params[:num]}")
    redirect_to certificate_order_path(@ssl_slug, @certificate_order)
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def credits
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.where{(workflow_state=='paid') & (certificate_contents.workflow_state == "new")} :
        current_user.ssl_account.cached_certificate_orders_credits).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def pending
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.pending :
        current_user.ssl_account.cached_certificate_orders_pending).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def filter_by_scope
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.send(params[:id].to_sym) :
      (current_user.role_symbols(current_user.ssl_account).join(',').split(',').include?(Role::INDIVIDUAL_CERTIFICATE) ?
           (current_user.ssl_account.cached_certificate_orders.joins{:certificate_contents}.search_assigned(current_user.id).send(params[:id].to_sym)) :
           (current_user.ssl_account.cached_certificate_orders.joins{:certificate_contents}.send(params[:id].to_sym))
      )).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def order_by_csr
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.unscoped{CertificateOrder.not_test} :
        current_user.ssl_account.cached_certificate_orders.unscoped{
          current_user.ssl_account.cached_certificate_orders.not_test}).order_by_csr.paginate(@p)
    id=@ssl_account.id if @ssl_account
    @certificate_orders = @certificate_orders.where{ssl_account_id==id} if(current_user.is_admin? and id)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def filter_by
    @certificate_orders = current_user.is_admin? ?
        (@ssl_account.try(:certificate_orders) || CertificateOrder) : current_user.ssl_account.cached_certificate_orders
    @certificate_orders = @certificate_orders.not_test.not_new.filter_by(params[:id]).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def incomplete
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.incomplete :
      current_user.ssl_account.cached_certificate_orders_incomplete).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def reprocessing
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.reprocessing :
      current_user.ssl_account.cached_certificate_orders.reprocessing).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # DELETE /certificate_orders/1
  # DELETE /certificate_orders/1.xml
  def destroy
    @certificate_order.destroy

    respond_to do |format|
      format.html { redirect_to(certificate_orders_url) }
      format.xml  { head :ok }
    end
  end

  def developer

  end

  def developers
    not_found and return unless is_sandbox?
  end

  def download
    t=File.new(@certificate_order.certificate_content.csr.signed_certificate.
      create_signed_cert_zip_bundle({components: true, is_windows: is_client_windows?}), "r")
    # End of the block  automatically closes the file.
    # Send it using the right mime type, with a download window and some nice file name.
    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
      :filename => @certificate_order.friendly_common_name+'.zip'
    # The temp file will be deleted some time...
    t.close
  end

  def download_other
    t=File.new(@certificate_order.certificate_content.csr.signed_certificate.
      create_signed_cert_zip_bundle(is_windows: is_client_windows?), "r")
    # End of the block  automatically closes the file.
    # Send it using the right mime type, with a download window and some nice file name.
    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
      :filename => @certificate_order.friendly_common_name+'.zip'
    # The temp file will be deleted some time...
    t.close
  end

  def download_certificates
    cert_orders = CertificateOrder.where(id: params[:co_ids].split('/')).includes(:signed_certificates)

    respond_to do |format|
      format.csv do
        send_data cert_orders.to_csv, filename: "certificates-#{DateTime.current.strftime("%Y-%m-%d_%H:%M:%S")}.csv"
      end
    end
  end

  # this function allows the customer to resubmit a new csr even while the order is being processed
  def start_over
    @certificate_order.start_over! unless @certificate_order.blank?
    flash[:notice] = "certificate order #{@certificate_order.ref} has been canceled and restarted"
  end

  def parse_csr
    c = Certificate.for_sale.find_by_product(params[:certificate])
    co = CertificateOrder.new(duration: 1)
    @cc = co.certificate_contents.build(certificate_order: co, ajax_check_csr: true)
    co = Order.setup_certificate_order(certificate: c, certificate_order: co)
    @cc.csr = Csr.new(body: params[:csr])
    @cc.valid?
  rescue
  end

  def admin_update
    if current_user.is_system_admins? or
        (current_user.ssl_account.epki_registrant and
            current_user.ssl_account.epki_registrant.applies_to_certificate_order?(@certificate_order))
      if params[:validate_iv] || params[:validate_ov]
        admin_validate
      elsif params[:unvalidate_iv] || params[:unvalidate_ov]
        admin_unvalidate
      else
        respond_to do |format|
          if @certificate_order.update_attributes(params[:certificate_order])
            format.js { render :json=>@certificate_order.to_json}
          else
            format.js { render :json=>@certificate_order.errors.to_json}
          end
        end
      end
    end
  end

  def switch_from_comodo
    returnObj = {}

    if current_user
      co = CertificateOrder.find_by_ref(params[:certificate_order_id])

      if co
        co.unchain_comodo
        returnObj['status'] = 'success'
      else
        returnObj['status'] = 'no-exist-cert-order'
      end
    else
      returnObj['status'] = 'no-user'
    end

    render :json => returnObj
  end

  def register_domains
    returnObj = {}
    @certificate_order = CertificateOrder.find_by_ref(params['id'])

    if current_user
      @certificate_order.certificate_content.locked_registrant.update_attribute(:domains, params['domains']) if @certificate_order
      returnObj['status'] = 'success'
    else
      returnObj['status'] = 'no-user'
    end

    render :json => returnObj
  end

  def save_attestation
    returnObj = AttestationCertificate.attestation_pass?(
        params[:attestation_cert],
        params[:attestation_issuer_cert])

    if returnObj
      if @certificate_order.attestation_certificate
        @certificate_order.attestation_certificate.body = params[:attestation_cert]
        @certificate_order.attestation_certificate.save!

        @certificate_order.attestation_issuer_certificate.body = params[:attestation_issuer_cert]
        @certificate_order.attestation_issuer_certificate.save!
      else
        create_attestation_certificate(
            params[:attestation_cert],
            @certificate_order.certificate_content,
            AttestationCertificate
        )
        create_attestation_certificate(
            params[:attestation_issuer_cert],
            @certificate_order.certificate_content,
            AttestationIssuerCertificate
        )
      end
    end

    render :json => returnObj
  end

  def remove_attestation
    @certificate_order.attestation_certificate.destroy!
    @certificate_order.attestation_issuer_certificate.destroy!

    render :json => true
  end

  private

  def create_attestation_certificate(cert, certificate_content, klass)
    attestation_certificate = klass.new
    attestation_certificate.body = cert
    attestation_certificate.type = klass.to_s
    attestation_certificate.certificate_content = certificate_content
    attestation_certificate.status = "stored"
    attestation_certificate.save!
  end

  def smime_client_create
    @certificate = Certificate.find params[:certificate_id]
    smime_client_parse_emails

    if @certificate && @emails.any?
      redirect_to new_order_path(@ssl_slug,
        emails: @emails,
        certificate: @certificate,
        smime_client_enrollment: true
      )
    else
      flash[:error] = "Please enter at least one valid email."
      render :smime_client_enrollment
    end
  end

  def smime_client_init
    find_tier
    @certificates = Certificate.get_smime_client_products(@tier)
    @certificate ||= @certificates.first

    co = CertificateOrder.new(
      duration: 2,
      ssl_account: (current_user.blank? ? nil : current_user.ssl_account),
      has_csr: false
    )
    co.certificate_contents << CertificateContent.new(domains: [])
    @certificate_order = Order.setup_certificate_order(
      certificate: @certificate, certificate_order: co
    )
  end

  def smime_client_duration
    @certificate = Certificate.find params[:certificate_id]
    partial = render_to_string(
      partial: 'certificate_orders/smime_client_enrollment/duration_form',
      layout: false
    )
    render json: {content: partial}, status: :ok
  end

  def client_smime_validate
    co = @certificate_order
    cc = co.certificate_content
    validations = co.certificate.client_smime_validations
    validated = if validations == 'iv_ov'
                  if @iv_exists.validated?
                    if co.registrant.epki_agreement?
                      co.registrant.applies_to_certificate_order?(co)
                    else
                      (co.locked_registrant || co.registrant).validated?
                    end
                  end
                elsif validations == 'iv'
                  @iv_exists.validated?
                else
                  true
                end

    if co.certificate.is_client_pro? && params[:saved_contacts].blank?
      cc.pend_validation! if !(cc.pending_validation? or cc.issued?)
      redirect_to document_upload_certificate_order_validation_path(
                      @ssl_slug, certificate_order_id: co.ref
                  )
    else
      if validated
        cc.validate! unless cc.validated?
        co.copy_iv_ov_validation_history(validations)
        redirect_to certificate_order_path(@ssl_slug, co.ref)
      else
        cc.pend_validation! if !(cc.pending_validation? or cc.issued?)
        redirect_to document_upload_certificate_order_validation_path(
                        @ssl_slug, certificate_order_id: co.ref
                    )
      end
    end
  end

  def admin_validate
    cc = @certificate_order.certificate_content
    ov = @certificate_order.locked_registrant
    lr = @certificate_order.locked_recipient

    if @certificate_order.certificate.is_smime_or_client?
      iv = @certificate_order.get_team_iv
      ov_iv = @certificate_order.certificate.requires_locked_registrant?

      if (params[:validate_iv] && iv && !iv.validated?)
        iv.validated!
        lr.validated! if lr && (iv.email == lr.email)
      end

      admin_validate_ov(ov)
      if (ov_iv && @certificate_order.iv_ov_validated?) || (!ov_iv && @certificate_order.iv_validated?)
        cc.validate! if !(cc.validated? or cc.pending_validation? or cc.issued?)
      end
    else
      admin_validate_ov(ov)
      # if ov.validated? && @certificate_order.domains_validated?
      #   @certificate_order.apply_for_certificate(
      #     mapping: @certificate_order.certificate_content.ca,
      #     current_user: current_user
      #   )
      # end
    end
    redirect_to certificate_order_path(@ssl_slug, @certificate_order.ref),
      notice: "Certificate order was successfully validated."
  end

  def admin_validate_ov(ov)
    if params[:validate_ov] && ov && !ov.validated?
      ov.validated!
      unless ov.parent_id.nil?
        parent = Contact.find(ov.parent_id)
        parent.validated! if parent && !parent.validated?
      end
    end
  end

  def admin_unvalidate
    cc = @certificate_order.certificate_content
    ov = @certificate_order.locked_registrant
    lr = @certificate_order.locked_recipient
    vt = params[:unvalidate_type]

    if @certificate_order.certificate.is_smime_or_client?
      iv = @certificate_order.get_team_iv
      if params[:unvalidate_iv] && vt && iv && lr && (iv.email == lr.email)
        iv.send("#{vt}!")
      end
      lr.send("#{vt}!") if params[:unvalidate_iv] && lr
      admin_unvalidate_ov(ov)
      unless @certificate_order.iv_ov_validated?
        cc.pend_validation! unless cc.pending_validation?
      end
    else
      admin_unvalidate_ov(ov)
    end
    redirect_to certificate_order_path(@ssl_slug, @certificate_order.ref),
      notice: "Certificate order was successfully updated."
  end

  def admin_unvalidate_ov(ov)
    vt = params[:unvalidate_type]
    if params[:unvalidate_ov] && vt && ov
      ov.send("#{vt}!")
      unless ov.parent_id.nil?
        parent = Contact.find(ov.parent_id)
        parent.send("#{vt}!") if parent
      end
    end
  end

  def registrants_on_edit
    setup_registrant
    if params[:registrant] == 'false'
      setup_registrant_from_locked
    else
      if @csr
        @registrant.company_name = @csr.organization unless @csr.organization.blank?
        @registrant.department = @csr.organization_unit unless @csr.organization_unit.blank?
        @registrant.city = @csr.locality unless @csr.locality.blank?
        @registrant.state = @csr.state unless @csr.state.blank?
        @registrant.email = @csr.email unless @csr.email.blank?
        @registrant.country = @csr.country unless @csr.country.blank?
      end
    end
  end

  def invite_recipient
    ssl = @certificate_order.ssl_account
    user_exists = User.find_by(email: params[:email])
    if user_exists
      user_exists_for_team = ssl.users.find_by(id: user_exists.id)

      if user_exists_for_team
        @iv_exists = ssl.individual_validations.find_by(user_id: user_exists_for_team.id)
      end

      unless @iv_exists
        # Add IV for user to team.
        @iv_exists = ssl.individual_validations.create(
          first_name: params[:first_name],
          last_name: params[:last_name],
          email: user_exists.email,
          status: user_exists_for_team ? Contact::statuses[:validated] : Contact::statuses[:in_progress],
          user_id: user_exists.id
        )
      end

      # Add user to team w/role individual_certificate
      unless user_exists_for_team
        user_exists.ssl_accounts << ssl
        user_exists.set_roles_for_account(
          ssl, [Role::get_individual_certificate_id]
        )
      end

      unless current_user.is_system_admins? && (params[:edit_locked_recipient] == 'true')
        @certificate_order.update_column(:assignee_id, user_exists.id)
      end
    else
      invite_new_recipient
    end
  end

  def invite_new_recipient
    new_user = current_user.invite_new_user({user: {
      email: params[:email],
      first_name: params[:first_name],
      last_name: params[:last_name],
    }})
    if new_user.persisted?
      invite_recipient
    end
  end

  def find_team_iv
    attrs = {}
    attrs[:id] = params[:saved_contacts] unless params[:saved_contacts].blank?
    attrs[:email] = params[:email].strip if attrs.empty? && !params[:email].blank?
    unless attrs.empty?
      @iv_exists = @certificate_order.ssl_account
        .individual_validations.find_by(attrs)
    end
    @assignee_id = @iv_exists.user_id if @iv_exists
  end

  def update_recipient(locked=nil)
    @certificate_order.reload
    current_recipient = locked ? @certificate_order.locked_recipient : @iv_exists
    if current_recipient
      current_recipient.update(
        %w{first_name last_name email}.inject({}) do |all, key|
          all[key.to_sym] = params[key.to_sym] unless params[key.to_sym].blank?
          all
        end
      )
    end
  end

  def recert(action)
    instance_variable_set("@"+action,CertificateOrder.unscoped.find_by_ref(params[:id]))
    instance_variable_get("@"+action)
  end

  def load_certificate_order
    if current_user
      @certificate_order = current_user.certificate_order_by_ref(params[:id])

      if @certificate_order.nil?
        co = current_user.ssl_accounts.includes(:certificate_orders).map(&:certificate_orders)
                 .flatten.find{|c| c.ref == params[:id]}
        if co
          @certificate_order = co
          if co.ssl_account != current_user.ssl_account && current_user.ssl_accounts.include?(co.ssl_account)

            current_user.set_default_ssl_account(co.ssl_account)
            set_ssl_slug
          end
        end
      end
    end
    render 'site/404_not_found', status: 404 unless @certificate_order
  end

  def construct_special_fields
    if params[:certificate_order]
      new_attributes = params[:certificate_order][:certificate_contents_attributes]['0'][:registrant_attributes] if params[:certificate_order][:certificate_contents_attributes]
      if new_attributes && new_attributes.any?
        cert_special_fields = @certificate_order.certificate.special_fields
        special_fields = {}
        if cert_special_fields.is_a?(Array) && cert_special_fields.any?
          new_attributes.each do |k, v|
            special_fields[k] = v if cert_special_fields.include?(k) && !v.blank?
          end
          new_attributes.delete_if {|rsp| cert_special_fields.include?(rsp)}
        end
        new_attributes.merge!(
          'special_fields' => (special_fields.blank? ? nil : special_fields)
        )
      end
    end
  end

  def setup_registrant(registrant_params=nil)
    cc = @certificate_order.certificate_content
    @registrant = unless cc.registrant.blank?
      cc.registrant.update(registrant_params) if registrant_params
      cc.registrant
    else
      registrant_params ? cc.build_registrant(registrant_params) : cc.build_registrant
    end
    setup_reusable_registrant(@registrant)
  end

  def setup_registrant_from_locked
    locked_registrant = @certificate_order.certificate_content.locked_registrant
    unless locked_registrant.blank?
      @registrant.assumed_name = locked_registrant.assumed_name
      @registrant.duns_number = locked_registrant.duns_number
      @registrant.department = locked_registrant.department
      @registrant.po_box = locked_registrant.po_box
      @registrant.address1 = locked_registrant.address1
      @registrant.address2 = locked_registrant.address2
      @registrant.address3 = locked_registrant.address3
      @registrant.city = locked_registrant.city
      @registrant.state = locked_registrant.state
      @registrant.postal_code = locked_registrant.postal_code
      @registrant.country = locked_registrant.country
      @registrant.title = locked_registrant.title
      @registrant.first_name = locked_registrant.first_name
      @registrant.last_name = locked_registrant.last_name
      @registrant.email = locked_registrant.email
      @registrant.phone = locked_registrant.phone
      @registrant.phone_number_approved = locked_registrant.phone_number_approved
      @registrant.country_code = locked_registrant.country_code
      @registrant.status = locked_registrant.status
      @registrant.parent_id = locked_registrant.parent_id
      @registrant.special_fields = locked_registrant.special_fields
    end
  end

  def setup_locked_registrant(cc_params=nil, cc)
    if cc_params && cc_params[:registrant_attributes]
      cc_params[:registrant_attributes].delete('id')

      unless params[:saved_contacts].blank?
        cc_params[:registrant_attributes].merge(
          {'parent_id' => params[:saved_contacts].to_i}
        )
      end

      if cc.locked_registrant.blank?
        cc.create_locked_registrant(cc_params[:registrant_attributes])
        cc.locked_registrant.save!
      elsif current_user.is_system_admins?
        cc.locked_registrant.update(cc_params[:registrant_attributes])
      end
      setup_reusable_registrant(cc.locked_registrant)
    end
  end

  def setup_reusable_registrant(from_registrant)
    if params[:save_for_later] &&
      from_registrant &&
      from_registrant.persisted? &&
      from_registrant.parent_id.nil? &&
      @reusable_registrant.nil?

      attr = from_registrant.attributes.delete_if do |k,v|
        %w{created_at updated_at id}.include?(k)
      end
      attr.merge!(
        'contactable_id' => @certificate_order.ssl_account.id,
        'contactable_type' => 'SslAccount',
        'type' => 'Registrant'
      )
      @reusable_registrant = Registrant.create(attr)
      if @reusable_registrant.persisted?
        from_registrant.update_column(:parent_id, @reusable_registrant.id)
      end
    end
  end

  def set_schedule_value
    @schedule_simple_type = [
        ['Hourly', '1'],
        ['Daily (at midnight)', '2'],
        ['Weekly (on Sunday)', '3'],
        ['Monthly (on the 1st)', '4'],
        ['Yearly (on 1st Jan)', '5']
    ]

    @schedule_weekdays = [
        ['Sunday', '0'], ['Monday', '1'], ['Tuesday', '2'], ['Wednesday', '3'],
        ['Thursday', '4'], ['Friday', '5'], ['Saturday', '6']
    ]

    @schedule_months = [
        ['January', '1'], ['Febrary', '2'], ['March', '3'], ['April', '4'], ['May', '5'], ['June', '6'],
        ['July', '7'], ['August', '8'], ['September', '9'], ['October', '10'], ['November', '11'], ['December', '12']
    ]

    @schedule_days = [
        ['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'], ['5', '5'], ['6', '6'],
        ['7', '7'], ['8', '8'], ['9', '9'], ['10', '10'], ['11', '11'], ['12', '12'],
        ['13', '13'], ['14', '14'], ['15', '15'], ['16', '16'], ['17', '17'], ['18', '18'],
        ['19', '19'], ['20', '20'], ['21', '21'], ['22', '22'], ['23', '23'], ['24', '24'],
        ['25', '25'], ['26', '26'], ['27', '27'], ['28', '28'], ['29', '29'], ['30', '30'], ['31', '31']
    ]

    @schedule_hours = [
        ['0', '0'], ['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'], ['5', '5'], ['6', '6'],
        ['7', '7'], ['8', '8'], ['9', '9'], ['10', '10'], ['11', '11'], ['12', '12'],
        ['13', '13'], ['14', '14'], ['15', '15'], ['16', '16'], ['17', '17'], ['18', '18'],
        ['19', '19'], ['20', '20'], ['21', '21'], ['22', '22'], ['23', '23']
    ]

    @schedule_minutes = [
        ['0', '0'], ['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'], ['5', '5'], ['6', '6'],
        ['7', '7'], ['8', '8'], ['9', '9'], ['10', '10'], ['11', '11'], ['12', '12'],
        ['13', '13'], ['14', '14'], ['15', '15'], ['16', '16'], ['17', '17'], ['18', '18'],
        ['19', '19'], ['20', '20'], ['21', '21'], ['22', '22'], ['23', '23'], ['24', '24'],
        ['25', '25'], ['26', '26'], ['27', '27'], ['28', '28'], ['29', '29'], ['30', '30'],
        ['31', '31'], ['32', '32'], ['33', '33'], ['34', '34'], ['35', '35'], ['36', '36'],
        ['37', '37'], ['38', '38'], ['39', '39'], ['40', '40'], ['41', '41'], ['42', '42'],
        ['43', '43'], ['44', '44'], ['45', '45'], ['46', '46'], ['47', '47'], ['48', '48'],
        ['49', '49'], ['50', '50'], ['51', '51'], ['52', '52'], ['53', '53'], ['54', '54'],
        ['55', '55'], ['56', '56'], ['57', '57'], ['58', '58'], ['59', '59']
    ]
  end

  def schedule(params)
    # Create or Update notification group
    if params[:schedule_type] == 'none' && params[:notification_group] != 'none'
      # notification_group = current_user.ssl_account.notification_groups.includes{:notification_groups_subjects}.where(ref: params[:notification_group]).first
      notification_group = current_user.ssl_account.cached_notification_groups
                               .includes(:notification_groups_subjects, :notification_groups_contacts, :schedules)
                               .where(ref: params[:notification_group]).first

      unless notification_group
        flash[:error] = "Some error occurs while getting notification group data. Please try again."
        @certificate = @certificate_order.certificate

        format.html { render 'submit_csr', :layout=>'application' }
      end
    else
      # Saving notification group info
      # notification_group = current_user.ssl_account.notification_groups.includes{:notification_groups_subjects}.find_by_friendly_name('ng-' + @certificate_order.ref)
      notification_group = current_user.ssl_account.cached_notification_groups
                               .includes(:notification_groups_subjects, :notification_groups_contacts, :schedules)
                               .find_by_friendly_name('ng-' + @certificate_order.ref)

      if notification_group.nil?
        notification_group = NotificationGroup.new(
            friendly_name: 'ng-' + @certificate_order.ref,
            scan_port: '443',
            notify_all: true,
            ssl_account: current_user.ssl_account,
            status: false,
        )
      end

      # Saving notification group triggers
      ['60', '30', '15', '0', '-15'].uniq.sort{|a, b| a.to_i <=> b.to_i}.reverse.each_with_index do |rt, i|
        notification_group.preferred_notification_group_triggers = rt.or_else(nil), ReminderTrigger.find(i + 1)
      end

      unless notification_group.save
        flash[:error] = "Some error occurs while saving notification group data. Please try again."
        @certificate = @certificate_order.certificate

        format.html { render 'submit_csr', :layout=>'application' }
      end
    end

    # if params[:notification_group] == 'none'
    #   # Saving notification group info
    #   notification_group = NotificationGroup.new(
    #       friendly_name: 'ng-' + @certificate_order.ref,
    #       scan_port: '443',
    #       notify_all: true,
    #       ssl_account: current_user.ssl_account,
    #       status: false,
    #   )
    #
    #   # Saving notification group triggers
    #   ['60', '30', '15', '0', '-15'].uniq.sort{|a, b| a.to_i <=> b.to_i}.reverse.each_with_index do |rt, i|
    #     notification_group.preferred_notification_group_triggers = rt.or_else(nil), ReminderTrigger.find(i + 1)
    #   end
    #
    #   unless notification_group.save
    #     flash[:error] = "Some error occurs while saving notification group data. Please try again."
    #     @certificate = @certificate_order.certificate
    #
    #     format.html { render 'submit_csr', :layout=>'application' }
    #   end
    # else
    #   notification_group = current_user.ssl_account.notification_groups.where(ref: params[:notification_group]).first
    #
    #   unless notification_group
    #     flash[:error] = "Some error occurs while getting notification group data. Please try again."
    #     @certificate = @certificate_order.certificate
    #
    #     format.html { render 'submit_csr', :layout=>'application' }
    #   end
    # end

    # Saving certificate order tag
    is_exist = notification_group.certificate_orders.where(id: @certificate_order.id)
    notification_group.notification_groups_subjects.build(
        subjectable_type: 'CertificateOrder', subjectable_id: @certificate_order.id
    ).save if is_exist.empty?

    # Saving subject tags
    # new_tags = @certificate_order.certificate_content.certificate_names.pluck(:id).map{ |val| val.to_s }
    new_tags = @certificate_order.certificate_contents.map(&:certificate_names).flatten.compact.map{|cn| cn.id.to_s}
    current_tags = notification_group.notification_groups_subjects
                       .where(subjectable_type: ['CertificateName', nil]).pluck(:domain_name, :subjectable_id)
                       .map{ |arr| arr[0].blank? ? arr[1].to_s : (arr[1].blank? ? arr[0] : (arr[0] + '---' + arr[1].to_s)) }
    add_tags = new_tags - current_tags
    add_tags.each do |subject|
      notification_group.notification_groups_subjects.build(
          subjectable_type: 'CertificateName', subjectable_id: subject
      ).save
    end

    # Saving contact tags
    current_tags = notification_group.notification_groups_contacts.where(email_address: current_user.email)
    notification_group.notification_groups_contacts.build(
        email_address: current_user.email
    ).save if current_tags.empty?

    # Saving schedule
    if (params[:schedule_type] == 'none' && params[:notification_group] == 'none') || params[:schedule_type] == 'simple'
      current_schedules = notification_group.schedules.pluck(:schedule_type)
      unless current_schedules.include? 'Simple'
        schedule_value_value =
            params[:schedule_type] == 'none' ?
                '2' :
                (params[:schedule_simple_type] ? params[:schedule_simple_type] : '2')

        notification_group.schedules.destroy_all
        notification_group.schedules.build(
            schedule_type: 'Simple',
            schedule_value: schedule_value_value
        ).save
      end
    elsif params[:schedule_type] == 'custom'
      current_schedules = notification_group.schedules.pluck(:schedule_type)
      if current_schedules.include? 'Simple'
        notification_group.schedules.destroy_all
      end

      # Weekday
      current_schedules = notification_group.schedules.where(schedule_type: 'Weekday').pluck(:schedule_value)
      if params[:weekday_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Weekday').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Weekday',
              schedule_value: 'All'
          ).save
        end
      else
        params[:weekday_custom_list] ||= []
        new_weekdays = params[:weekday_custom_list] - current_schedules
        old_weekdays = current_schedules - params[:weekday_custom_list]

        notification_group.schedules.where(schedule_type: 'Weekday', schedule_value: old_weekdays).destroy_all
        new_weekdays.each do |weekday|
          notification_group.schedules.build(
              schedule_type: 'Weekday',
              schedule_value: weekday
          ).save
        end
      end

      # Month
      current_schedules = notification_group.schedules.where(schedule_type: 'Month').pluck(:schedule_value)
      if params[:month_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Month').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Month',
              schedule_value: 'All'
          ).save
        end
      else
        params[:month_custom_list] ||= []
        new_months = params[:month_custom_list] - current_schedules
        old_months = current_schedules - params[:month_custom_list]

        notification_group.schedules.where(schedule_type: 'Month', schedule_value: old_months).destroy_all
        new_months.each do |month|
          notification_group.schedules.build(
              schedule_type: 'Month',
              schedule_value: month
          ).save
        end
      end

      # Day
      current_schedules = notification_group.schedules.where(schedule_type: 'Day').pluck(:schedule_value)
      if params[:day_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Day').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Day',
              schedule_value: 'All'
          ).save
        end
      else
        params[:day_custom_list] ||= []
        new_days = params[:day_custom_list] - current_schedules
        old_days = current_schedules - params[:day_custom_list]

        notification_group.schedules.where(schedule_type: 'Day', schedule_value: old_days).destroy_all
        new_days.each do |day|
          notification_group.schedules.build(
              schedule_type: 'Day',
              schedule_value: day
          ).save
        end
      end

      # Hour
      current_schedules = notification_group.schedules.where(schedule_type: 'Hour').pluck(:schedule_value)
      if params[:hour_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Hour').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Hour',
              schedule_value: 'All'
          ).save
        end
      else
        params[:hour_custom_list] ||= []
        new_hours = params[:hour_custom_list] - current_schedules
        old_hours = current_schedules - params[:hour_custom_list]

        notification_group.schedules.where(schedule_type: 'Hour', schedule_value: old_hours).destroy_all
        new_hours.each do |hour|
          notification_group.schedules.build(
              schedule_type: 'Hour',
              schedule_value: hour
          ).save
        end
      end

      # Minute
      current_schedules = notification_group.schedules.where(schedule_type: 'Minute').pluck(:schedule_value)
      if params[:minute_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Minute').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Minute',
              schedule_value: 'All'
          ).save
        end
      else
        params[:minute_custom_list] ||= []
        new_minutes = params[:minute_custom_list] - current_schedules
        old_minutes = current_schedules - params[:minute_custom_list]

        notification_group.schedules.where(schedule_type: 'Minute', schedule_value: old_minutes).destroy_all
        new_minutes.each do |minute|
          notification_group.schedules.build(
              schedule_type: 'Minute',
              schedule_value: minute
          ).save
        end
      end
    end

    # if params[:notification_group] == 'none'
    #   if params[:schedule_type] == 'true'
    #     current_schedules = notification_group.schedules.pluck(:schedule_type)
    #     unless current_schedules.include? 'Simple'
    #       notification_group.schedules.destroy_all
    #
    #       notification_group.schedules.build(
    #           schedule_type: 'Simple',
    #           schedule_value: params[:schedule_simple_type]
    #       ).save
    #     end
    #   else
    #     current_schedules = notification_group.schedules.pluck(:schedule_type)
    #     if current_schedules.include? 'Simple'
    #       notification_group.schedules.destroy_all
    #     end
    #
    #     # Weekday
    #     current_schedules = notification_group.schedules.where(schedule_type: 'Weekday').pluck(:schedule_value)
    #     if params[:weekday_type] == 'true'
    #       unless current_schedules.include? 'All'
    #         notification_group.schedules.where(schedule_type: 'Weekday').destroy_all
    #         notification_group.schedules.build(
    #             schedule_type: 'Weekday',
    #             schedule_value: 'All'
    #         ).save
    #       end
    #     else
    #       params[:weekday_custom_list] ||= []
    #       new_weekdays = params[:weekday_custom_list] - current_schedules
    #       old_weekdays = current_schedules - params[:weekday_custom_list]
    #
    #       notification_group.schedules.where(schedule_type: 'Weekday', schedule_value: old_weekdays).destroy_all
    #       new_weekdays.each do |weekday|
    #         notification_group.schedules.build(
    #             schedule_type: 'Weekday',
    #             schedule_value: weekday
    #         ).save
    #       end
    #     end
    #
    #     # Month
    #     current_schedules = notification_group.schedules.where(schedule_type: 'Month').pluck(:schedule_value)
    #     if params[:month_type] == 'true'
    #       unless current_schedules.include? 'All'
    #         notification_group.schedules.where(schedule_type: 'Month').destroy_all
    #         notification_group.schedules.build(
    #             schedule_type: 'Month',
    #             schedule_value: 'All'
    #         ).save
    #       end
    #     else
    #       params[:month_custom_list] ||= []
    #       new_months = params[:month_custom_list] - current_schedules
    #       old_months = current_schedules - params[:month_custom_list]
    #
    #       notification_group.schedules.where(schedule_type: 'Month', schedule_value: old_months).destroy_all
    #       new_months.each do |month|
    #         notification_group.schedules.build(
    #             schedule_type: 'Month',
    #             schedule_value: month
    #         ).save
    #       end
    #     end
    #
    #     # Day
    #     current_schedules = notification_group.schedules.where(schedule_type: 'Day').pluck(:schedule_value)
    #     if params[:day_type] == 'true'
    #       unless current_schedules.include? 'All'
    #         notification_group.schedules.where(schedule_type: 'Day').destroy_all
    #         notification_group.schedules.build(
    #             schedule_type: 'Day',
    #             schedule_value: 'All'
    #         ).save
    #       end
    #     else
    #       params[:day_custom_list] ||= []
    #       new_days = params[:day_custom_list] - current_schedules
    #       old_days = current_schedules - params[:day_custom_list]
    #
    #       notification_group.schedules.where(schedule_type: 'Day', schedule_value: old_days).destroy_all
    #       new_days.each do |day|
    #         notification_group.schedules.build(
    #             schedule_type: 'Day',
    #             schedule_value: day
    #         ).save
    #       end
    #     end
    #
    #     # Hour
    #     current_schedules = notification_group.schedules.where(schedule_type: 'Hour').pluck(:schedule_value)
    #     if params[:hour_type] == 'true'
    #       unless current_schedules.include? 'All'
    #         notification_group.schedules.where(schedule_type: 'Hour').destroy_all
    #         notification_group.schedules.build(
    #             schedule_type: 'Hour',
    #             schedule_value: 'All'
    #         ).save
    #       end
    #     else
    #       params[:hour_custom_list] ||= []
    #       new_hours = params[:hour_custom_list] - current_schedules
    #       old_hours = current_schedules - params[:hour_custom_list]
    #
    #       notification_group.schedules.where(schedule_type: 'Hour', schedule_value: old_hours).destroy_all
    #       new_hours.each do |hour|
    #         notification_group.schedules.build(
    #             schedule_type: 'Hour',
    #             schedule_value: hour
    #         ).save
    #       end
    #     end
    #
    #     # Minute
    #     current_schedules = notification_group.schedules.where(schedule_type: 'Minute').pluck(:schedule_value)
    #     if params[:minute_type] == 'true'
    #       unless current_schedules.include? 'All'
    #         notification_group.schedules.where(schedule_type: 'Minute').destroy_all
    #         notification_group.schedules.build(
    #             schedule_type: 'Minute',
    #             schedule_value: 'All'
    #         ).save
    #       end
    #     else
    #       params[:minute_custom_list] ||= []
    #       new_minutes = params[:minute_custom_list] - current_schedules
    #       old_minutes = current_schedules - params[:minute_custom_list]
    #
    #       notification_group.schedules.where(schedule_type: 'Minute', schedule_value: old_minutes).destroy_all
    #       new_minutes.each do |minute|
    #         notification_group.schedules.build(
    #             schedule_type: 'Minute',
    #             schedule_value: minute
    #         ).save
    #       end
    #     end
    #   end
    # end
  end

  def setup_managed_csr_domains(params)
    # if params[:add_to_manager] && params[:add_to_manager] == 'true'
    #   managed_csr = ManagedCsr.new
    #   managed_csr.body = params[:certificate_order][:certificate_contents_attributes]['0'.to_sym][:signing_request]
    #   managed_csr.friendly_name = managed_csr.common_name || managed_csr.sha1_hash
    #   managed_csr.ssl_account_id = current_user.ssl_account.id
    #
    #   unless managed_csr.save
    #     flash[:error] = "Some error occurs while adding this csr to the csr manager."
    #     @certificate = @certificate_order.certificate
    #
    #     format.html { render 'submit_csr', :layout=>'application' }
    #   end
    #
    #   @certificate_order.managed_csrs << managed_csr
    # end
    #
    # @certificate_order.managed_csrs << ManagedCsr.find_by_ref(params[:managed_csr]) if params[:managed_csr] != 'none'
    # @certificate_order.managed_domains << Domain.where(id: params[:managed_domains]) if params[:managed_domains]

    if params[:add_to_manager] == 'true' and !['none',nil].include? params[:managed_csr]
      managed_csr = ManagedCsr.new
      managed_csr.body = params[:certificate_order][:certificate_contents_attributes]['0'.to_sym][:signing_request]
      managed_csr.friendly_name = managed_csr.common_name || managed_csr.sha1_hash
      managed_csr.ssl_account_id = current_user.ssl_account.id
      @certificate_order.managed_csrs << managed_csr unless
          @certificate_order.managed_csrs.map(&:public_key_sha1).include? managed_csr.public_key_sha1

      unless managed_csr.errors.blank?
        flash[:error] = "Some error occurs while adding this csr to the csr manager."
        @certificate = @certificate_order.certificate

        format.html { render 'submit_csr', :layout=>'application' }
      end

      @certificate_order.managed_csrs << managed_csr
    end
  end

  def set_algorithm_and_size
    @integrated_algorithm = [
        ['RSA', 'RSASSA-PKCS1-v1_5'],
        ['ECDSA', 'ECDSA']
    ]

    # @hash_algorithm = [
    #     ['SHA-256', 'SHA-256'],
    #     ['SHA-384', 'SHA-384'],
    #     ['SHA-512', 'SHA-512']
    # ]

    @sign_algorithm = [
        ['RSASSA-PKCS1-v1_5', 'RSASSA-PKCS1-v1_5'],
        ['ECDSA', 'ECDSA'],
        ['RSA-PSS', 'RSA-PSS']
    ]

    @rsa_key_size = [
        ['2048', '2048'],
        ['4096', '4096']
    ]

    @ecc_key_size = [
        ['256', '256'],
        ['384', '384']
    ]
  end
end
