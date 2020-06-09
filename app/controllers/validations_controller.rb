open3 = "open3"
open3.insert(0,'win32/') if RUBY_PLATFORM =~ /mswin32/
require open3
require 'zip/zipfilesystem'
require 'tempfile'
include Open3

class ValidationsController < ApplicationController
  before_action :require_user, only: [:index, :new, :edit, :show, :upload, :document_upload, :get_asynch_domains,
                                      :cancel_validation_process]
  before_action :find_validation, only: [:update, :new]
  before_action :find_certificate_order, only: [:new, :edit, :show, :upload, :document_upload, :request_approve_phone_number]
  before_action :set_supported_languages, only: [:verification]
  before_action :set_row_page, only: [:index, :search]

  filter_access_to :all
  filter_access_to [:upload, :document_upload, :verification, :email_verification_check, :automated_call,
                    :phone_verification_check, :register_callback], :require=>:update
  filter_access_to :requirements, :send_dcv_email, :domain_control, :ev, :organization, require: :read
  filter_access_to :update, :new, :attribute_check=>true
  filter_access_to :edit, :show, :attribute_check=>true
  filter_access_to :admin_manage, :attribute_check=>true
  filter_access_to :send_to_ca, require: :super_user_manage
  filter_access_to :get_asynch_domains, :remove_domains, :get_email_addresses, :send_callback,
                   :add_super_user_email, :request_approve_phone_number, :cancel_validation_process, :require=>:ajax
  in_place_edit_for :validation_history, :notes

  def search
    index
  end

  def new
    url = nil
    cc = @certificate_order.certificate_content

    if !@certificate_order.certificate.is_server?
      url = document_upload_certificate_order_validation_url(certificate_order_id: @certificate_order.ref)
    elsif cc.csr.blank?
      url = edit_certificate_order_path(@ssl_slug, @certificate_order)
    else
      if cc.issued?
        checkout = {checkout: "true"}
        if cc.signed_certificate
          flash.now[:notice] = "SSL certificate has been issued"
        elsif @certificate_order.domains_validated?
          flash.now[:notice] = "All domains have been validated, please wait for certificate issuance"
        end

        respond_to do |format|
          format.html { redirect_to certificate_order_path({id: @certificate_order.ref}.merge!(checkout))}
        end
      else
        if cc.contacts_provided? or cc.info_provided?
          cc.pend_validation!(host: request.host_with_port)
        end

        # @all_validated = true
        @validated_domains = ''
        @caa_check_domains = ''
        validated_domain_arry = []
        caa_check_domain_arry = []
        public_key_sha1 = Settings.compare_public_key ? cc.cached_csr_public_key_sha1 : nil
        unless cc.ca_id.blank?
          cnames = cc.certificate_names.includes(:validated_domain_control_validations)
          # need to get fresh copy of certificate names since async validation can corrupt the cache
          Rails.cache.delete(@certificate_order.ssl_account.get_all_certificate_names_cache_label(cnames.map(&:name),
                                                                                                  "validated"))
          team_cnames = @certificate_order.ssl_account.all_certificate_names(cnames.map(&:name),"validated").
              includes(:validated_domain_control_validations)

          # Team level validation check
          @ds = {}
          cnames.each do |cn|
            team_level_validated = false

            team_cnames.each do |team_cn|
              if team_cn.name == cn.name
                team_dcv = team_cn.validated_domain_control_validations.last

                if team_dcv && (Settings.compare_public_key ? team_dcv.validated?(nil,public_key_sha1) : true)
                  team_level_validated = true

                  @ds[team_cn.name] = {}
                  @ds[team_cn.name]['method'] = team_dcv.dcv_method
                  @ds[team_cn.name]['attempted_on'] = team_dcv.created_at
                  if team_cn.caa_passed
                    @ds[team_cn.name]['caa_check'] = 'passed'
                  else
                    @ds[team_cn.name]['caa_check'] = 'failed'
                    caa_check_domain_arry << team_cn.name
                  end
                end

                break if team_level_validated
              end
            end

            (validated_domain_arry << cn.name) if cn.validated_domain_control_validations.last
          end

          @all_validated=@certificate_order.domains_validated?
          if @all_validated and cc.signed_certificate.blank? and !cc.issued?
            cc.validate! if cc.pending_validation?
            api_log_entry=@certificate_order.apply_for_certificate(
                mapping: cc.ca, current_user: current_user)

            if api_log_entry == :blocklist_error
              matches = cc.infringement.map { |entry| entry[:matches] }.flatten.map{ |match| "The field <b>#{match[:field]}</b> with value of <b>#{match[:value]}</b> matches an item in our blocklist." }.uniq.join("<br>")
              error = "Certificate was not issued. Our support team has been notified.<br><br> #{matches}"
              flash[:error] = error
            end

            if api_log_entry and api_log_entry.instance_of?(SslcomCaRequest) and api_log_entry.response=~/Check CAA/
              invalid_domain = api_log_entry.response.scan(/Not allowed to issue certificate for dnsName (.*?+)\.\s/).flatten
              flash[:error] =
                "CAA validation failed. Domains do not pass CAA check: #{invalid_domain.join(', ')}. See https://#{Settings.portal_domain}/how-to/configure-caa-records-to-authorize-ssl-com/"
            end
          end

          @validated_domains = validated_domain_arry.join(',')
          @caa_check_domains = caa_check_domain_arry.join(',')
        else
          mdc_validation = ComodoApi.mdc_status(@certificate_order)
          @ds = mdc_validation.domain_status

          if @ds
            # tmpCnt = 0
            # before = DateTime.now
            names=cc.certificate_names.find_by_domains(@ds.keys)
            @ds.each do |key, value|
              if value['status'].casecmp('validated') != 0
                @all_validated = false if @all_validated
              else
                validated_domain_arry << key
                ext_order_number = @certificate_order.external_order_number || 'eon'
                cache = nil # Rails.cache.read(params[:certificate_order_id] + ':' + ext_order_number + ':' + key)

                if cache.blank?
                  cn = names.find_by_name(key)
                  dcv = cn.blank? ? nil : cn.domain_control_validations.last
                  value['attempted_on'] = dcv.blank? ? 'n/a' : dcv.created_at

                  if Settings.enable_caa && cn.try(:caa_passed)
                    value['caa_check'] = 'passed'
                  else
                    value['caa_check'] = 'failed'
                    caa_check_domain_arry << key
                  end

                  # Rails.cache.write(params[:certificate_order_id] + ':' + ext_order_number + ':' + key, value['attempted_on'])
                else
                  value['attempted_on'] = cache
                end
              end
            end
            # after = DateTime.now
            # subtract = after.to_i - before.to_i

            @validated_domains = validated_domain_arry.join(',')
            @caa_check_domains = caa_check_domain_arry.join(',')

            # if all_validated
            #   url=certificate_order_path(@ssl_slug, @certificate_order)
            # end
          else
            @all_validated = false
            # flash[:error] = "Currently Comodoca API is under working, please try again after some minutes."
          end
        end
      end
    end
    redirect_to url and return unless url.blank?
  end

  def dcv_validate
    @certificate_order = CertificateOrder.find_by_ref(params['certificate_order_id'])
    cc = @certificate_order.certificate_content
    if(params['authenticity_token'])
      identifier = params['validate_code']
      cnames = cc.certificate_names
      all_validated = true
      cnames.includes(:domain_control_validations).each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv.identifier == identifier
          dcv.update_attribute(:identifier_found, true)
        end
        all_validated = false unless dcv.identifier_found
      end
      if all_validated
        cc.validate! unless cc.validated?
        @certificate_order.apply_for_certificate(mapping:
           @certificate_order.certificate.cas.ssl_account_or_general_default(current_user.ssl_account).last) unless cc.ca_id.blank?
      end
    end
  end

  def remove_domains
    result_obj = {}

    if current_user
      domain_name_arry = params['domain_names'].split(',')
      # order_number = CertificateOrder.find_by_ref(params['certificate_order_id']).external_order_number
      certificate_order = current_user.certificate_order_by_ref(params[:certificate_order_id])
      certificate_content = certificate_order.certificate_content
      certificate_names = certificate_content.certificate_names

      unless certificate_content.ca_id.nil?
        domains = certificate_content.domains
        domains_from_cert_names = certificate_names.pluck(:name)

        if domains.size == domains_from_cert_names.size && (domains & domains_from_cert_names).size == domains.size
          remain_domains = domains - domain_name_arry
        else
          remain_domains = domains_from_cert_names - domain_name_arry
        end

        certificate_content.update_column :domains, remain_domains
      end

      certificate_names.includes(:domain_control_validations).where{ name >> domain_name_arry }.each do |cn_obj|
        cleanup = -> {
          # Remove Domain from Notification Group
          NotificationGroup.auto_manage_cert_name(certificate_content, 'delete', cn_obj)

          # Remove Domain Object
          dcvs = cn_obj.domain_control_validations
          if dcvs.size > 0
            dcvs.delete_all
          end
          cn_obj.destroy

          # TODO: Remove cache for removed domain
          Rails.cache.delete(params[:certificate_order_id] + ':' + cn_obj.name)
        }
        if certificate_content.ca_id.nil?
          res = ComodoApi.auto_remove_domain(domain_name: cn_obj, order_number: certificate_order.external_order_number)

          error_code = -1
          error_message = ''

          if res.index('errorCode') && res.index('errorMessage')
            error_code = res.split('&')[0].split('=')[1].to_i
            error_message = res.split('&')[1].split('=')[1]
          elsif res.index('errorCode') && !res.index('errorMessage')
            error_code = 0
          else
            error_message = res
          end

          if error_code.zero?
            cleanup.call
          else
            result_obj[cn_obj.name] = error_message.gsub("+", " ").gsub("%27", "'").gsub("%21", "!")
          end
        else
          cleanup.call
        end
      end
    else
      result_obj['no-user'] = "true"
    end

    render :json => result_obj
  end

  def get_email_addresses
    returnObj = {}
    if current_user
      addresses = CertificateName.candidate_email_addresses(params['domain_name'])
      addresses.delete("none")

      returnObj['caa_check'] = ''
      returnObj['new_emails'] = {}

      addresses.each do |addr|
        returnObj['new_emails'][addr] = addr
      end
    else
      returnObj['no-user'] = "true"
    end

    render :json => returnObj
  end

  def add_super_user_email
    returnObj = {}

    if current_user
      params['domain_emails'].each do |domain_email|
        CertificateName.add_email_address_candidate(domain_email.split('|')[0], domain_email.split('|')[1])
      end

      returnObj['status'] = "true"
    else
      returnObj['no-user'] = "true"
    end

    render :json => returnObj
  end

  def get_asynch_domains
    co = (current_user.is_system_admins? ? CertificateOrder.includes(:certificate_contents) :
              current_user.certificate_orders).find_by_ref(params[:certificate_order_id])
    cn = co.certificate_content.certificate_names.find_by_name(params['domain_name']) if co

    returnObj = Rails.cache.fetch(cn&.get_asynch_cache_label) do
      if cn
        ds = params['domain_status']

        if co.certificate_content.ca
          dcv = cn.validated_domain_control_validations.last
          domain_status =
              if dcv
                "validated"
              else
                co.ssl_account.other_dcvs_satisfy_domain(cn)
                dcv = cn.validated_domain_control_validations.last
                if dcv
                  "validated"
                else
                  dcv = cn.domain_control_validations.last
                  "pending"
                end
              end
          if dcv
            domain_method = dcv.email_address ? dcv.email_address : dcv.dcv_method
          else
            domain_status = !ds.blank? && ds['status'] ? ds['status'] : nil
            domain_method = !ds.blank? && ds['method'] ? ds['method'] : nil
          end
        else
          domain_status = !ds.blank? && ds['status'] ? ds['status'] : nil
          domain_method = !ds.blank? && ds['method'] ? ds['method'] : nil
        end

        addresses =
          if co.certificate_content.ca.blank? and co.external_order_number
            ComodoApi.domain_control_email_choices(cn.name).email_address_choices
          else
            CertificateName.candidate_email_addresses(cn.non_wildcard_name)
          end
        addresses.delete("none")

        optionsObj = {}
        viaEmail = {}
        viaCSR = {}

        if dcv or !ds.blank?
          addresses.each do |addr|
            viaEmail[addr] = addr
          end

          viaCSR['http_csr_hash'] = 'CSR hash text file using http://'
          viaCSR['https_csr_hash'] = 'CSR hash text file using https://'
          viaCSR['cname_csr_hash'] = 'Add cname entry'

          optionsObj['Validation via email'] = viaEmail
          optionsObj['Validation via csr hash'] = viaCSR

          {
            'tr_info' => {
              'options' => optionsObj,
              'slt_option' => domain_method ?
                                  domain_method.downcase.gsub('pre-validated %28', '').gsub('%29', '').gsub(' ', '_') : nil,
              'pretest' => 'n/a',
              'attempt' => domain_method ? domain_method.downcase.gsub('%28', ' ').gsub('%29', ' ') : '',
              'attempted_on' => dcv.blank? ? 'n/a' : dcv.created_at.strftime('%Y-%m-%d %H:%M:%S'),
              'status' => domain_status ? domain_status.downcase : '',
              'caa_check' => ''
            },
            'tr_instruction' => false
          }
        else
          optionsObj = {}
          addresses ||= CertificateName.candidate_email_addresses(cn.non_wildcard_name)

          viaEmail = {}
          viaCSR = {}

          addresses.each do |addr|
            viaEmail[addr] = addr
          end

          viaCSR['http_csr_hash'] = 'CSR hash text file using http://'
          viaCSR['https_csr_hash'] = 'CSR hash text file using https://'
          viaCSR['cname_csr_hash'] = 'Add cname entry'

          optionsObj['Validation via email'] = viaEmail
          optionsObj['Validation via csr hash'] = viaCSR

          le = cn.domain_control_validations.last_emailed

          {
            'tr_info' => {
              'options' => optionsObj,
              'slt_option' => le.blank? ? nil : le.email_address,
              'pretest' => 'n/a',
              'attempt' => 'validation not performed yet',
              'attempted_on' => 'n/a',
              'status' => 'waiting',
              'caa_check' => ''
            },
            'tr_instruction' => false
          }
        end
      end
    end

    render :json => returnObj
  end

  def index
    # p = {:page => params[:page]}
    @certificate_orders =
      if !params[:search].blank? && (@search = params[:search])
        current_user.is_admin? ?
           (@ssl_account.try(:certificate_orders) || CertificateOrder.with_includes)
             .not_test.search_with_csr(params[:search]).unvalidated.not_csr_blank :
        current_user.ssl_account.certificate_orders.not_test.search(params[:search]).unvalidated.not_csr_blank
      else
        current_user.is_admin? ?
            (@ssl_account.try(:certificate_orders) || CertificateOrder.with_includes).unvalidated.not_csr_blank :
            current_user.ssl_account.certificate_orders.unvalidated.not_csr_blank
      end

    @certificate_orders = @certificate_orders.paginate(@p)

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def show_document_file
    release = Release.find(params[:id])
    if current_user.try(:can_view_release?, Release.find(params[:id]))
      content = release.content
      send_file content.private_full_filename
      send_file @appraisal.doc.path, :type => @appraisal.doc_content_type, :disposition => 'attachment'
    else
      render :status=>403
    end
  end

  def send_dcv_email
    if params[:domain_control_validation_email] && params[:domain_control_validation_id]
      @dcv = DomainControlValidation.find(params[:domain_control_validation_id])
      @dcv.send_to params[:domain_control_validation_email]
    end
    respond_to do |format|
      format.js {render json: (@dcv.errors.blank? ? @dcv : @dcv.errors).to_json, status: :ok}
    end
  end

  def upload_for_registrant
    @i = 0
    @error = []
    @files = params[:filedata] || []

    if params[:filedata]
      upload_documents(params[:filedata], :saved_registrant_documents)
    end

    if @error.blank?
      if @files.blank?
        flash[:error] = "Documents were not saved, please upload at least one file."
      else
        files_were = (@i > 1 || @i==0) ? "documents were" : "document was"
        flash[:notice] = "#{@i.in_words.capitalize} (#{@i}) #{files_were} successfully saved."
      end
    else
      flash[:error] = "Failed to upload documents due to errors: #{@error.join(', ')}"
    end
    redirect_to contact_path(@ssl_slug, @registrant.id, saved_contact: true)
  end

  #user can select to upload documents or do dcv (email or http) or do both
  def upload
    @i = 0
    @error = []
    @files = params[:filedata] || []
    @files += params[:iv_filedata] if params[:iv_filedata]
    @files += params[:ov_filedata] if params[:ov_filedata]

    unless params[:refer_to_others].blank? || params[:refer_to_others]=="false"
      attrs=%w(email_addresses other_party_requestable_type other_party_requestable_id preferred_sections preferred_show_order_number)
      @other_party_validation_request =
        OtherPartyValidationRequest.new(Hash[*attrs.map{|a|[a.to_sym,params[a.to_sym]] if params[a.to_sym]}.
            compact.flatten])
      current_user.other_party_requests << @other_party_validation_request
        unless @other_party_validation_request.valid?
          @error<<@other_party_validation_request.errors.full_messages
          flash[:opvr_error]=true
        end
        flash[:opvr]=true
        flash[:email_addresses]=params[:email_addresses]
    end

    upload_documents(@files, :validation) if params[:filedata]
    upload_documents(params[:iv_filedata], :iv_documents) if params[:iv_filedata]
    upload_documents(params[:ov_filedata], :ov_documents) if params[:ov_filedata]

    respond_to do |format|
      if @error.blank? && (@other_party_validation_request.blank? ? true : @other_party_validation_request.valid?)
        unless @files.blank?
          files_were = (@i > 1 or @i==0)? "documents were" : "document was"
          flash[:notice] = "#{@i.in_words.capitalize} (#{@i}) #{files_were}
            successfully saved."
          @certificate_order.confirmation_recipients.map{|r|r.split(" ")}.flatten.uniq.each do |c|
            OrderNotifier.validation_documents_uploaded(c, @certificate_order, @files).deliver
          end
          OrderNotifier.validation_documents_uploaded(Settings.notify_address, @certificate_order, @files).deliver
          OrderNotifier.validation_documents_uploaded_comodo("evdocs@comodo.com", @certificate_order, @files).
              deliver if (@certificate_order.certificate.is_ev? && @certificate_order.ca_name=="comodo")
        end
        checkout={}
        if @certificate_order.certificate_content.contacts_provided?
          @certificate_order.certificate_content.pend_validation!(host: request.host_with_port) if @other_party_validation_request.blank?
          checkout={checkout: "true"}
        end
        @validation_histories = @certificate_order.validation_histories
        format.html { redirect_to certificate_order_path({id: @certificate_order.ref}.merge!(checkout))}
        format.xml { render :xml => @release,
          :status => :created,
          :location => @release }
      else
        (flash[:error] = @error.is_a?(Array) ? @error.join(", ") : @error) unless @error.blank?
        format.html { redirect_to new_certificate_order_validation_path(
            @certificate_order) }
        format.xml { render :xml => @release.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      #protected for admins only
      if current_user.is_admin?
        @co = CertificateOrder.find params[:certificate_order]
        cc = @co.certificate_content
        vrs = @validation.validation_rulings
        vrs.each do |vr|
          case params["ruling_decision_#{vr.id}".to_sym]
          when ValidationRuling::UNAPPROVED
            vr.unapprove! unless vr.unapproved?
            vr.notes.create(:title=>ValidationRuling::UNAPPROVED,
              :note=>params["ruling_reason_#{vr.id}".to_sym], :user=>current_user)
            @co.site_seal.deactivate! unless @co.site_seal.deactivated?
          when ValidationRuling::MORE_REQUIRED
            vr.require_more! unless vr.more_required?
            vr.notes.create(:title=>ValidationRuling::MORE_REQUIRED,
              :note=>params["ruling_reason_#{vr.id}".to_sym], :user=>current_user)
            @co.site_seal.deactivate! unless @co.site_seal.deactivated?
          when ValidationRuling::APPROVED
            vr.approve! unless vr.approved?
            vr.notes.create(:title=>ValidationRuling::APPROVED,
              :note=>'requirement for "'+vr.
              validation_rule.description+'" has been met.', :user=>current_user)
              @co.site_seal.fully_activate! unless
                @co.site_seal.fully_activated?
          end
        end

        is_validated = false
        if params[:validation_complete]=="true"
          cc.validate! unless cc.validated?
          is_validated = true
        elsif params[:validation_complete]=="false"
          cc.pend_validation! if cc.validated?
        else
          if vrs.all?(&:approved?)
            unless cc.validated?
              cc.validate! if !cc.issued?
              is_validated = true
            end
          else
            unless cc.pending_validation?
              cc.pend_validation!(host: request.host_with_port)
              is_validated = true
            end
          end
        end

        notify_customer(vrs) if params[:email_customer]
        #include the username making this adjustment
        vr_json = @validation.to_json.chop << ',"by_user":"' +
          current_user.login + '","is_validated":"' + is_validated.to_s + '"}'
        format.js { render :json=>vr_json}
      else
        format.js { render :json=>@validation.errors.to_json}
      end
    end
  end

  def send_to_ca(options={})
    co=CertificateOrder.find_by_ref(params[:certificate_order_id])
    result = co.apply_for_certificate(params.merge(current_user: current_user, allow_multiple_certs_per_content: true))
    unless options[:send_to_ca].blank? or [Ca::CERTLOCK_CA,Ca::SSLCOM_CA,Ca::MANAGEMENT_CA].include?(params[:ca])
      co.certificate_content.pend_validation!(send_to_ca: false, host: request.host_with_port) if
          result.order_number && !co.certificate_content.pending_validation?
    end
    respond_to do |format|
      format.js {render :json=>{:result=>render_to_string(:partial=>
          'sent_ca_result', locals: {ca_response: result})}}
    end
  end

  def send_callback
    returnObj = {}
    @certificate_order = CertificateOrder.find_by_ref(params['certificate_order_id'])

    if current_user
      if @certificate_order
        # Generate Token
        co_token = CertificateOrderToken.new
        co_token.certificate_order = @certificate_order
        co_token.ssl_account = @certificate_order.ssl_account
        co_token.user = current_user
        co_token.is_expired = false
        co_token.due_date = 7.days.from_now
        co_token.token = (SecureRandom.hex(8)+Time.now.to_i.to_s(32))[0..19]
        co_token.phone_verification_count = 0
        co_token.phone_call_count = 0
        co_token.status = CertificateOrderToken::PENDING_STATUS
        co_token.save!

        # Send callback email
        params['emails'].each do |email|
          OrderNotifier.callback_send(@certificate_order, co_token.token, email).deliver
        end

        returnObj['status'] = 'success'
      end
    else
      returnObj['status'] = 'no-user'
    end

    render :json => returnObj
  end

  def verification
    @status = true
    @token = params[:token]

    # Get CertificateOrderToken Object using emailed token url.
    @certificate_order_token = CertificateOrderToken.find_by_token(params[:token])

    if @certificate_order_token
      if @certificate_order_token.status == CertificateOrderToken::EXPIRED_STATUS
        @status = false
        flash[:error] = 'This token has been expired.'
      elsif @certificate_order_token.status == CertificateOrderToken::FAILED_STATUS
        @status = false
        flash[:error] = 'This token has been failed.'
      elsif @certificate_order_token.status == CertificateOrderToken::DONE_STATUS
        @status = false
        flash[:error] = 'This token has been used before.'
      else
        if @certificate_order_token.due_date < DateTime.now
          @certificate_order_token.update_columns(
              is_expired: true,
              status: CertificateOrderToken::EXPIRED_STATUS
          )
          @status = false
          flash[:error] = 'This token has been expired.'
        else
          passed_token = (SecureRandom.hex(8)+params[:token])[0..19]
          @certificate_order_token.update_column :passed_token, passed_token

          # Get phone number and country from locked_registrant of certificate_order.
          phone_number = @certificate_order_token.certificate_order.locked_registrant.phone || ''
          country_code = @certificate_order_token.certificate_order.locked_registrant.country_code || '1'
          @mobile_number = "(+" + country_code + ") " + phone_number

          # Get all timezone
          @time_zones = ActiveSupport::TimeZone.all
                            .map{|tz| ["(GMT#{formatted_offset(Timezone[tz.tzinfo.name].utc_offset)}) #{tz.name}" , (Timezone[tz.tzinfo.name].utc_offset / 3600).to_s + ':' + tz.tzinfo.name]}
                            .sort_by{|e| e[1].split(':')[0].to_i}

          if @certificate_order_token.callback_type == CertificateOrderToken::CALLBACK_SCHEDULE
            @callback_type = 'schedule'
            @callback_method = @certificate_order_token.callback_method.upcase
            @callback_datetime = @certificate_order_token.callback_datetime.in_time_zone(@certificate_order_token.callback_timezone.split(':')[1]).strftime('%Y-%m-%d %I:%M %p %:z')
            @callback_locale = @certificate_order_token.locale.blank? ? 'en' : @certificate_order_token.locale

            flash[:notice] = 'It has been already scheduled automated callback.'
          elsif @certificate_order_token.callback_type == CertificateOrderToken::CALLBACK_MANUAL
            @callback_type = 'manual'
            @callback_method = @certificate_order_token.callback_method.upcase
            @callback_datetime = @certificate_order_token.callback_datetime.in_time_zone(@certificate_order_token.callback_timezone.split(':')[1]).strftime('%Y-%m-%d %I:%M %p %:z')
            @callback_locale = @certificate_order_token.locale.blank? ? 'en' : @certificate_order_token.locale

            flash[:notice] = 'It has been already scheduled manual callback.'
          else
            @callback_type = 'none'
            @callback_locale = 'en'
          end
        end
      end
    else
      @status = false
      flash[:error] = 'It is untrustworthy token.'
    end
  end

  def automated_call
    returnObj = {}

    # if current_user
    co_token = CertificateOrderToken.where(
        token: params[:token],
        status: CertificateOrderToken::PENDING_STATUS
    ).first

    if co_token
      phone_call_count = co_token.phone_call_count.nil? ? 0 : co_token.phone_call_count.to_i
      if phone_call_count >= CertificateOrderToken::PHONE_CALL_LIMIT_MAX_COUNT
        co_token.update_column :status, CertificateOrderToken::FAILED_STATUS
        returnObj['status'] = 'reached_to_max'
      else
        # Generate new passed token.
        passed_token = (SecureRandom.hex(8)+co_token.passed_token)[0..19]
        co_token.update_column :passed_token, passed_token

        # Increase phone call count.
        phone_call_count = co_token.phone_call_count.to_i + 1
        co_token.update_column :phone_call_count, phone_call_count

        # Get phone number and country from locked_registrant of certificate_order.
        phone_number = co_token.certificate_order.locked_registrant.phone || ''
        country_code = co_token.certificate_order.locked_registrant.country_code || '1'

        # # Get dial code from country.
        # country_code = ISO3166::Country.new(country).country_code

        @response = Authy::PhoneVerification.start(
            via: params[:method],
            country_code: country_code,
            phone_number: phone_number,
            locale: params[:locale]
        )

        if @response.ok?
          returnObj['passed_token'] = passed_token
          returnObj['status'] = 'success'
        else
          returnObj['status'] = 'failed'
        end
      end
    else
      returnObj['status'] = 'incorrect-token'
    end
    # else
    #   returnObj['status'] = 'no-user'
    # end

    render :json => returnObj
  end

  def phone_verification_check
    returnObj = {}

    # if current_user
    co_token = CertificateOrderToken.where(
        token: params[:token],
        passed_token: params[:passed_token],
        status: CertificateOrderToken::PENDING_STATUS
    ).first

    if co_token
      phone_verification_count = co_token.phone_verification_count.nil? ? 0 : co_token.phone_verification_count.to_i
      if phone_verification_count >= CertificateOrderToken::PHONE_VERIFICATION_LIMIT_MAX_COUNT
        co_token.update_column :status, CertificateOrderToken::FAILED_STATUS
        returnObj['status'] = 'reached_to_max'
      else
        # Generate new passed token.
        passed_token = (SecureRandom.hex(8)+params[:passed_token])[0..19]
        co_token.update_column :passed_token, passed_token

        # Increase phone verification count.
        phone_verification_count = co_token.phone_verification_count.to_i + 1
        co_token.update_column :phone_verification_count, phone_verification_count

        # Get phone number and country from locked_registrant of certificate_order.
        phone_number = co_token.certificate_order.locked_registrant.phone || ''
        country_code = co_token.certificate_order.locked_registrant.country_code || '1'

        # # Get dial code for country
        # country_code = ISO3166::Country.new(country).country_code

        @response = Authy::PhoneVerification.check(
            verification_code: params[:phone_verification_code],
            country_code: country_code,
            phone_number: phone_number
        )

        if @response.ok?
          phone_number = '+' + country_code + '-' + phone_number
          co_token.update_columns(status: CertificateOrderToken::DONE_STATUS, phone_number: phone_number)
          # TODO: After add info_verified state to workflow on certificate content, it should be commented out.
          # co_token.certificate_order.certificate_content.validate!

          returnObj['status'] = 'success'
        else
          returnObj['passed_token'] = passed_token
          returnObj['status'] = 'failed'
        end
      end
    else
      returnObj['status'] = 'incorrect-token'
    end
    # else
    #   returnObj['status'] = 'no-user'
    # end

    render :json => returnObj
  end

  def register_callback
    returnObj = {}

    co_token = CertificateOrderToken.where(
        token: params[:token],
        status: CertificateOrderToken::PENDING_STATUS
    ).first

    dtz = DateTime.strptime(
        params[:callback_date] + ' ' + params[:callback_time] + ' ' + (params[:callback_timezone].split(':')[0].include?('-') ? '' : '+') + params[:callback_timezone].split(':')[0],
        '%m/%d/%Y %I:%M %p %:z'
    )

    if co_token
      co_token.update_columns(
          callback_method: params[:callback_method],
          callback_type: params[:callback_type],
          callback_timezone: params[:callback_timezone],
          callback_datetime: dtz,
          is_callback_done: (params[:callback_type] == CertificateOrderToken::CALLBACK_MANUAL ? nil : false),
          locale: params[:locale]
      )

      if params[:callback_type] == CertificateOrderToken::CALLBACK_MANUAL
        OrderNotifier.manual_callback_send(co_token.certificate_order, dtz.strftime('%Y-%m-%d %I:%M %p %z')).deliver
        returnObj['status'] = 'success-manual'
      else
        returnObj['status'] = 'success-schedule'
      end

      returnObj['callback_method'] = params[:callback_method].upcase
      returnObj['callback_datetime'] = dtz.strftime('%Y-%m-%d %I:%M %p %:z')

    else
      returnObj['status'] = 'incorrect-token'
    end

    render :json => returnObj
  end

  def request_approve_phone_number
    returnObj = {}

    if current_user
      super_users = User.search_super_user.uniq
      super_users.each do |super_user|
        OrderNotifier.request_phone_number_approve(@certificate_order, super_user.email).deliver
      end

      returnObj['status'] = 'success'
    else
      returnObj['status'] = 'session_expired'
    end

    render :json => returnObj
  end

  def cancel_validation_process
    returnObj = {}
    co = (current_user.is_system_admins? ? CertificateOrder :
              current_user.certificate_orders).find_by_ref(params[:certificate_order_id])

    if co
      if co.certificate_contents.size == 0
        returnObj['status'] = 'no-exist-cert-content'
      else
        co.certificate_content.destroy
        if co.certificate_contents.size == 0
          cc=CertificateContent.new
          cc.certificate_order=co
          cc.save
        end
        returnObj['status'] = 'success'
      end
    else
      returnObj['status'] = 'no-exist-cert-order'
    end

    render :json => returnObj
  end

  private

  def set_row_page
    preferred_row_count = current_user.preferred_validate_row_count
    @per_page = params[:per_page] || preferred_row_count.or_else("10")
    CertificateOrder.per_page = @per_page if CertificateOrder.per_page != @per_page

    if @per_page != preferred_row_count
      current_user.preferred_validate_row_count = @per_page
      current_user.save(validate: false)
    end

    @p = {page: (params[:page] || 1), per_page: @per_page}
  end

  def formatted_offset(seconds)
    format = '%s%02d:%02d'

    sign = (seconds < 0 ? '-' : '+')
    hours = seconds.abs / 3600
    minutes = (seconds.abs % 3600) / 60
    format % [sign, hours, minutes]
  end

  def upload_documents(files, type=:validation)
    i=0
    @zip_file_name = ""

    files.each do |file|
      @created_releases = []
      if (file.respond_to?(:content_type) && file.content_type.include?("zip")) ||
          (file.respond_to?(:original_filename) && file.original_filename.include?("zip"))
        logger.info "creating directory #{Rails.root}/tmp/zip/temp"
        FileUtils.mkdir_p "#{Rails.root}/tmp/zip/temp" if !File.exist?("#{Rails.root}/tmp/zip/temp")
        if file.size > Settings.max_content_size.to_i.megabytes
          break @error = <<-EOS
            Too Large: zip file #{file.original_filename} is larger than
            #{help.number_to_human_size(Settings.max_content_size.to_i.megabytes)}
          EOS
        end
        @zip_file_name=file.original_filename
        File.open("#{Rails.root}/tmp/zip/#{file.original_filename}", "wb") do |f|
          f.write(file.read)
        end
        zf = Zip::ZipFile.open("#{Rails.root}/tmp/zip/#{file.original_filename}")
        if zf.size > Settings.max_num_releases.to_i
          break @error = <<-EOS
            Too Many Files: zip file #{file.original_filename} contains more than
            #{Settings.max_num_releases.to_i} files.
          EOS
        end
        zf.each do |entry|
          begin
            fpath = File.join("#{Rails.root}/tmp/zip/temp/",entry.name.downcase)
            if(File.exists?(fpath))
              File.delete(fpath)
            end
            zf.extract(entry, fpath)
            @created_releases << create_with_attachment(LocalFile.new(fpath), type)
            i+=1
          rescue Errno::ENOENT, Errno::EISDIR
            @error = "Invalid contents: zip entries with directories not allowed"
            break
          ensure
            if (File.exists?(fpath))
              if File.directory?(fpath)
                FileUtils.remove_dir fpath, :force=>true
              else
                FileUtils.remove_file fpath, :force=>true
              end
            end
            @created_releases.each {|release| release.destroy} unless @error.blank?
          end
        end
        File.delete(zf.name) if (File.exists?(zf.name))
        @created_releases.each do |doc|
          doc.errors.each{|attr,msg|
            @error << "#{attr} #{msg}: " }
        end
      else
        vh = create_with_attachment(LocalFile.new(file.path, file.original_filename), type)
        vh.errors.each{|attr,msg|
          @error << "#{attr} #{msg}: " }
        i+=1 if vh
        @error << "Error: Document for #{file.original_filename} was not
          created. Please notify system admin at #{support_email}" unless vh
      end
    end
    @i += i
  end

  def validation_stage_checkout_in_progress?
    co.certificate_content.contacts_provided?
  end

  def build_other_party_validation

  end

  def create_with_attachment(file, type=:validation)
    @val_history = ValidationHistory.new(document: file)
    unless type == :saved_registrant_documents
      @certificate_order.validation.validation_histories << @val_history
    end
    @val_history.save
    create_iv_attachment if type == :iv_documents
    create_ov_attachment if type == :ov_documents
    create_saved_registrant_attachment if type == :saved_registrant_documents
    @val_history
  end

  def create_saved_registrant_attachment
    if @val_history.valid? && params[:registrant_id]
      @registrant = Registrant.find params[:registrant_id]
      if @registrant
        @registrant.validation_histories << @val_history
        contacts = LockedRegistrant.where(parent_id: @registrant.id)
        if contacts.any?
          # If client or s/mime certificate used this registrant, then add
          # documents to locked registrant and certificate order as well.
          CertificateOrder.joins(certificate_contents: :locked_registrant)
            .where("contacts.id IN (?)", contacts.ids).each do |co|
              if co.certificate.is_smime_or_client?
                co.locked_registrant.validation_histories << @val_history
                co.validation.validation_histories << @val_history
              end
            end
        end
      end
    end
  end

  def create_iv_attachment
    if @val_history.valid?
      iv_exists = @certificate_order.get_team_iv
      if iv_exists
        iv_exists.validation_histories << @val_history
        lrc = @certificate_order.locked_recipient
        if lrc && (lrc.user_id == iv_exists.user_id)
          lrc.validation_histories << @val_history
        end
      end
    end
  end

  def create_ov_attachment
    if @val_history.valid?
      lr = @certificate_order.locked_registrant
      unless lr.nil?
        lr.validation_histories << @val_history
        if lr.parent_id
          reusable_registrant = Registrant.find_by(id: lr.parent_id)
        end
        if reusable_registrant
          reusable_registrant.validation_histories << @val_history
        end
      end
    end
  end

  def find_validation
    @validation=
        if params[:id]
          Validation.find(params[:id])
        elsif params[:certificate_order_id]
          CertificateOrder.find_by_ref(params[:certificate_order_id]).try(:validation)
        end
    render :text => "404 Not Found", :status => 404 unless @validation
  end

  def notify_customer(validation_rulings)
    recips = [@co.certificate_content.administrative_contact].compact
    recips << @co.certificate_content.validation_contact if @co&.certificate_content&.validation_contact&.email&.downcase != @co&.certificate_content&.administrative_contact&.email&.downcase
    recips.compact.each do |c|
      if validation_rulings.all?(&:approved?)
        OrderNotifier.validation_approve(c, @co).deliver
      else
        OrderNotifier.validation_unapprove(c, @co, @validation).deliver
      end
    end
  end

  def find_certificate_order
    @certificate_order = (current_user.is_system_admins? ? CertificateOrder.includes(:validation) : current_user.certificate_orders.includes(:validation)).find_by_ref(params[:certificate_order_id])
    @validation = @certificate_order.validation if @certificate_order
  end

  # def domain_validation
  #   @exist_ext_order_number = @certificate_order.external_order_number
  #   if @exist_ext_order_number
  #     mdc_validation = ComodoApi.mdc_status(@certificate_order)
  #     # sdc_validation = ComodoApi.collect_ssl(@certificate_order)
  #     @ds = mdc_validation.domain_status
  #   end
  # end

  # source should be a zip file.
  # target should be a directory to output the contents to.

  def unzip_file(source, target)
    # Create the target directory.
    # We'll ignore the error scenario where
    begin
      Dir.mkdir(target) unless File.exists? target
    end

    Zip::ZipFile.open(source) do |zipfile|
      dir = zipfile.dir

      dir.entries('.').each do |entry|
        zipfile.extract(entry, "#{target}/#{entry}")
      end
    end
  rescue Zip::ZipDestinationFileExistsError => ex
    # I'm going to ignore this and just overwrite the files.
  rescue => ex
    puts ex
  end

  def help
    Helpers.instance
  end

  def set_supported_languages
    @supported_languages = [
        ['Afrikaans', 'af'],
        ['Arabic', 'ar'],
        ['Catalan', 'ca'],
        ['Chinese', 'zh'],
        ['Chinese (Mandarin)', 'zh-CN'],
        ['Chinese (Cantonese)', 'zh-HK'],
        ['Croatian', 'hr'],
        ['Czech', 'cs'],
        ['Danish', 'da'],
        ['Dutch', 'nl'],
        ['English', 'en'],
        ['Finnish', 'fi'],
        ['French', 'fr'],
        ['German', 'de'],
        ['Greek', 'el'],
        ['Hebrew', 'he'],
        ['Hindi', 'hi'],
        ['Hungarian', 'hu'],
        ['Indonesian', 'id'],
        ['Italian', 'it'],
        ['Japanese', 'ja'],
        ['Korean', 'ko'],
        ['Malay', 'ms'],
        ['Norwegian', 'nb'],
        ['Polish', 'pl'],
        ['Portuguese - Brazil', 'pt-BR'],
        ['Portuguese', 'pt'],
        ['Romanian', 'ro'],
        ['Russian', 'ru'],
        ['Spanish', 'es'],
        ['Swedish', 'sv'],
        ['Tagalog', 'tl']
    ]
  end
end
