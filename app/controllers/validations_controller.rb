open3 = "open3"
open3.insert(0,'win32/') if RUBY_PLATFORM =~ /mswin32/
require open3
require 'zip/zipfilesystem'
require 'tempfile'
include Open3

class ValidationsController < ApplicationController
  before_filter :require_user, only: [:index, :new, :edit, :show, :upload, :document_upload, :get_asynch_domains]
  before_filter :find_validation, only: [:update, :new]
  before_filter :find_certificate_order, only: [:new, :edit, :show, :upload, :document_upload]

  filter_access_to :all
  filter_access_to [:upload, :document_upload], :require=>:update
  filter_access_to :requirements, :send_dcv_email, :domain_control, :ev, :organization, require: :read
  filter_access_to :update, :new, :attribute_check=>true
  filter_access_to :edit, :show, :attribute_check=>true
  filter_access_to :admin_manage, :attribute_check=>true
  filter_access_to :send_to_ca, require: :sysadmin_manage
  filter_access_to :get_asynch_domains, :remove_domains, :get_email_addresses, :require=>:ajax
  in_place_edit_for :validation_history, :notes

  def search
    index
  end

  def new
    url = nil
    cc = @certificate_order.certificate_content

    if @certificate_order.certificate.is_code_signing?
      url = document_upload_certificate_order_validation_url(certificate_order_id: @certificate_order.ref)
    else
      if cc.issued? # or @certificate_order.all_domains_validated?
        checkout = {checkout: "true"}
        flash.now[:notice] = "All domains have been validated, please wait for certificate issuance" if @certificate_order.all_domains_validated?
        respond_to do |format|
          format.html { redirect_to certificate_order_path({id: @certificate_order.ref}.merge!(checkout))}
        end
      else
        if cc.contacts_provided? or cc.info_provided?
          cc.pend_validation!(host: request.host_with_port)
        end

        @all_validated = true
        @validated_domains = ''
        @caa_check_domains = ''
        validated_domain_arry = []
        caa_check_domain_arry = []
        public_key_sha1=cc.csr.public_key_sha1
        unless cc.ca.blank?
          cnames = cc.certificate_names.includes(:domain_control_validations)
          team_cnames = @certificate_order.ssl_account.all_certificate_names.includes(:domain_control_validations)

          # Team level validation check
          @ds = {}
          cnames.each do |cn|
            team_level_validated = false

            team_cnames.each do |team_cn|
              if team_cn.name == cn.name
                team_dcv = team_cn.domain_control_validations.last

                if team_dcv && team_dcv.validated?(public_key_sha1)
                  team_level_validated = true

                  @ds[team_cn.name] = {}
                  @ds[team_cn.name]['method'] = team_dcv.dcv_method
                  @ds[team_cn.name]['attempted_on'] = team_dcv.created_at
                  if team_cn.caa_passed
                    @ds[team_cn.name]['caa_check'] = 'passsed'
                  else
                    @ds[team_cn.name]['caa_check'] = 'failed'
                    caa_check_domain_arry << team_cn.name
                  end
                end

                break if team_level_validated
              end
            end

            unless team_level_validated
              @all_validated = false
            else
              validated_domain_arry << cn.name
            end
          end

          if @all_validated and cc.signed_certificate.blank?
            cc.validate! if cc.pending_validation?
            @certificate_order.
                apply_for_certificate(mapping:
                      @certificate_order.certificate_content.ca,
                      current_user: current_user)
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
      cnames.each do |cn|
        dcv = cn.domain_control_validations.last
        if dcv.identifier == identifier
          dcv.update_attribute(:identifier_found, true)
        end
        all_validated = false unless dcv.identifier_found
      end
      if all_validated
        cc.validate! unless cc.validated?
        @certificate_order.apply_for_certificate(mapping:
           @certificate_order.certificate.cas.ssl_account_or_general_default(current_user.ssl_account).last) unless @certificate_order.certificate_content.ca.blank?
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

      certificate_names.where{ name >> domain_name_arry }.each do |cn_obj|
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
            # Remove Domain from Notification Group
            NotificationGroup.auto_manage_cert_name(certificate_content, 'delete', cn_obj)

            # Remove Domain Object
            cn_obj.destroy

            # TODO: Remove cache for removed domain
            # Rails.cache.delete(params[:certificate_order_id] + ':' + domain_name)
            Rails.cache.delete(params[:certificate_order_id] + ':' + cn_obj.name)
          else
            result_obj[cn_obj.name] = error_message.gsub("+", " ").gsub("%27", "'").gsub("%21", "!")
          end
        else
          dcvs = cn_obj.domain_control_validations
          dcvs.destroy_all if dcvs.size > 0

          # Remove Domain from Notification Group
          NotificationGroup.auto_manage_cert_name(certificate_content, 'delete', cn_obj)

          # Remove Domain Object
          cn_obj.destroy

          # TODO: Remove cache for removed domain
          Rails.cache.delete(params[:certificate_order_id] + ':' + cn_obj.name)
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
      addresses = params['total_domains'].to_i > Validation::COMODO_EMAIL_LOOKUP_THRESHHOLD ?
                      DomainControlValidation.email_address_choices(params['domain_name']) :
                      ComodoApi.domain_control_email_choices(params['domain_name']).email_address_choices
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

  def get_asynch_domains
    co = (current_user.is_system_admins? ? CertificateOrder :
              current_user.certificate_orders).find_by_ref(params[:certificate_order_id])
    cn = co.certificate_content.certificate_names.find_by_name(params['domain_name']) if co

    returnObj = Rails.cache.fetch("#{cn.domain_control_validations.
        last.try(:cache_key)}/get_asynch_domains/#{params['domain_name']}") do
      if cn
        ds = params['domain_status']
        dcv = cn.domain_control_validations.last

        if dcv and co.certificate_content.ca
          domain_status = dcv.identifier_found? ? "validated" : "pending"
          domain_method = dcv.email_address ? dcv.email_address : dcv.dcv_method
        else
          domain_status = !ds.blank? && ds['status'] ? ds['status'] : nil
          domain_method = !ds.blank? && ds['method'] ? ds['method'] : nil
        end

        addresses =
          if co.certificate_content.ca.blank? and co.external_order_number
            params['domain_count'].to_i > Validation::COMODO_EMAIL_LOOKUP_THRESHHOLD ?
                DomainControlValidation.email_address_choices(cn.name) :
                ComodoApi.domain_control_email_choices(cn.name).email_address_choices
          else
            DomainControlValidation.email_address_choices(cn.name)
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
              'attempted_on' => dcv.blank? ? 'n/a' : dcv.created_at,
              'status' => domain_status ? domain_status.downcase : '',
              'caa_check' => ''
            },
            'tr_instruction' => false
          }
        else
          optionsObj = {}
          addresses = DomainControlValidation.email_address_choices(cn.name)

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
    p = {:page => params[:page]}
    @certificate_orders =
      if @search = params[:search]
       current_user.is_admin? ?
           (@ssl_account.try(:certificate_orders) || CertificateOrder).not_test.search_with_csr(params[:search]).unvalidated :
        current_user.ssl_account.cached_certificate_orders.not_test.
          search(params[:search]).unvalidated
      else
        current_user.is_admin? ?
            (@ssl_account.try(:certificate_orders) || CertificateOrder).unvalidated :
            current_user.ssl_account.cached_certificate_orders.unvalidated
      end.paginate(p)
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
    unless hide_both?
      if hide_documents? || params[:domain_control_validation_id]
        @dcv = DomainControlValidation.find(params[:domain_control_validation_id])
        if params[:method]=="email" && params[:domain_control_validation_email]
          @dcv.send_to params[:domain_control_validation_email]
          @error<<'Please select a valid verification email address.' unless @dcv.errors.blank?
        elsif params[:method]=="http"
          #verify http dcv
          http_or_s = @certificate_order.csr.dcv_verified?
          unless http_or_s
            @error<<"Please be sure #{@certificate_order.csr.dcv_url} (or https://) is publicly available"
          else
            @dcv.hash_satisfied(http_or_s)
            @certificate_order.validation.approve! unless
              (@certificate_order.validation.approved? || @certificate_order.validation.approved_through_override?)
          end
        end
      elsif hide_dcv? || @files.blank?
        @error<<'Please select one or more files to upload.'
      end
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
        if params[:validation_complete]
          cc.validate! unless cc.validated?
          is_validated = true
        else
          if vrs.all?(&:approved?)
            unless cc.validated?
              cc.validate!
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
    result = co.apply_for_certificate(params.merge(current_user: current_user))
    unless options[:send_to_ca].blank? or [Ca::CERTLOCK_CA,Ca::SSLCOM_CA,Ca::MANAGEMENT_CA].include?(params[:ca])
      co.certificate_content.pend_validation!(send_to_ca: false, host: request.host_with_port) if result.order_number && !co.certificate_content.pending_validation?
    end
    respond_to do |format|
      format.js {render :json=>{:result=>render_to_string(:partial=>
          'sent_ca_result', locals: {ca_response: result})}}
    end
  end

  private

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
          created. Please notify system admin at #{Settings.support_email}" unless vh
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
    recips = [@co.certificate_content.administrative_contact]
    recips << @co.certificate_content.validation_contact unless
      @co.certificate_content.validation_contact.email.downcase==
      @co.certificate_content.administrative_contact.email.downcase
    recips.each do |c|
      if validation_rulings.all?(&:approved?)
        OrderNotifier.validation_approve(c, @co).deliver
      else
        OrderNotifier.validation_unapprove(c, @co, @validation).deliver
      end
    end
  end

  def find_certificate_order
    @certificate_order = (current_user.is_system_admins? ? CertificateOrder : current_user.certificate_orders).find_by_ref(params[:certificate_order_id])
    @validation = @certificate_order.validation if @certificate_order
  end

  # def domain_validation
  #   byebug
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
end
