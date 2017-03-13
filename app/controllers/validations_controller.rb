open3 = "open3"
open3.insert(0,'win32/') if RUBY_PLATFORM =~ /mswin32/
require open3
require 'zip/zipfilesystem'
require 'tempfile'
include Open3

class ValidationsController < ApplicationController
  before_filter :find_validation, only: [:update, :new]
  before_filter :find_certificate_order, only: [:new, :edit, :show, :upload, :document_upload]
  before_filter :require_user, only: [:index, :new]
  filter_access_to :all
  filter_access_to [:upload, :document_upload], :require=>:update
  filter_access_to :requirements, :send_dcv_email, :domain_control, :ev, :organization, require: :read
  filter_access_to :update, :new, :attribute_check=>true
  filter_access_to :edit, :show, :attribute_check=>true
  filter_access_to :admin_manage, :attribute_check=>true
  filter_access_to :send_to_ca, require: :admin_manage
  in_place_edit_for :validation_history, :notes

  def search
    index
  end

  def new
    if @certificate_order.certificate_content.contacts_provided?
        @certificate_order.certificate_content.pend_validation!
    elsif @certificate_order.certificate_content.issued?
      checkout={checkout: "true"}
      respond_to do |format|
        format.html { redirect_to certificate_order_path({id: @certificate_order.id}.merge!(checkout))}
      end
    end
  end

  def index
    p = {:page => params[:page]}
    @certificate_orders =
      if @search = params[:search]
       current_user.is_admin? ?
           (@ssl_account.try(:certificate_orders) || CertificateOrder).not_test.search(params[:search]).unvalidated :
        current_user.ssl_account.certificate_orders.not_test.
          search(params[:search]).unvalidated
      else
        current_user.is_admin? ?
            (@ssl_account.try(:certificate_orders) || CertificateOrder).unvalidated :
            current_user.ssl_account.certificate_orders.unvalidated
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

  #user can select to upload documents or do dcv (email or http) or do both
  def upload
    i=0
    error=[]
    @zip_file_name = ""
    @files = params[:filedata] || []
    unless params[:refer_to_others].blank? || params[:refer_to_others]=="false"
      attrs=%w(email_addresses other_party_requestable_type other_party_requestable_id preferred_sections preferred_show_order_number)
      @other_party_validation_request =
        OtherPartyValidationRequest.new(Hash[*attrs.map{|a|[a.to_sym,params[a.to_sym]] if params[a.to_sym]}.
            compact.flatten])
      current_user.other_party_requests << @other_party_validation_request
        unless @other_party_validation_request.valid?
          error<<@other_party_validation_request.errors.full_messages
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
          error<<'Please select a valid verification email address.' unless @dcv.errors.blank?
        elsif params[:method]=="http"
          #verify http dcv
          http_or_s = @certificate_order.csr.dcv_verified?
          unless http_or_s
            error<<"Please be sure #{@certificate_order.csr.dcv_url} (or https://) is publicly available"
          else
            @dcv.hash_satisfied(http_or_s)
            @certificate_order.validation.approve! unless
              (@certificate_order.validation.approved? || @certificate_order.validation.approved_through_override?)
          end
        end
      elsif hide_dcv? || @files.blank?
        error<<'Please select one or more files to upload.'
      end
    end
    @files.each do |file|
      @created_releases = []
      if (file.respond_to?(:content_type) && file.content_type.include?("zip")) ||
          (file.respond_to?(:original_filename) && file.original_filename.include?("zip"))
        logger.info "creating directory #{Rails.root}/tmp/zip/temp"
        FileUtils.mkdir_p "#{Rails.root}/tmp/zip/temp" if !File.exist?("#{Rails.root}/tmp/zip/temp")
        if file.size > Settings.max_content_size.to_i.megabytes
          break error = <<-EOS
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
          break error = <<-EOS
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
            @created_releases << create_with_attachment(LocalFile.new(fpath))
            i+=1
          rescue Errno::ENOENT, Errno::EISDIR
            error = "Invalid contents: zip entries with directories not allowed"
            break
          ensure
            if (File.exists?(fpath))
              if File.directory?(fpath)
                FileUtils.remove_dir fpath, :force=>true
              else
                FileUtils.remove_file fpath, :force=>true
              end
            end
            @created_releases.each {|release| release.destroy} unless error.blank?
          end
        end
        File.delete(zf.name) if (File.exists?(zf.name))
        @created_releases.each do |doc|
          doc.errors.each{|attr,msg|
            error << "#{attr} #{msg}: " }
        end
      else
        vh = create_with_attachment LocalFile.new(file.path, file.original_filename)
        vh.errors.each{|attr,msg|
          error << "#{attr} #{msg}: " }
        i+=1 if vh
        error << "Error: Document for #{file.original_filename} was not
          created. Please notify system admin at #{Settings.support_email}" unless vh
      end
    end
    respond_to do |format|
      if error.blank? && (@other_party_validation_request.blank? ? true : @other_party_validation_request.valid?)
        unless @files.blank?
          files_were = (i > 1 or i==0)? "documents were" : "document was"
          flash[:notice] = "#{i.in_words.capitalize} (#{i}) #{files_were}
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
          @certificate_order.certificate_content.pend_validation! if @other_party_validation_request.blank?
          checkout={checkout: "true"}
        end
        @validation_histories = @certificate_order.validation_histories
        format.html { redirect_to certificate_order_path({id: @certificate_order.id}.merge!(checkout))}
        format.xml { render :xml => @release,
          :status => :created,
          :location => @release }
      else
        (flash[:error] = error.is_a?(Array) ? error.join(", ") : error) unless error.blank?
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
        if vrs.all?(&:approved?)
          cc.validate! unless cc.validated?
        else
          cc.pend_validation! unless cc.pending_validation?
        end
        notify_customer(vrs) if params[:email_customer]
        #include the username making this adjustment
        vr_json = @validation.to_json.chop << ',"by_user":"'+
          current_user.login+'"}'
        format.js { render :json=>vr_json}
      else
        format.js { render :json=>@validation.errors.to_json}
      end
    end
  end

  def send_to_ca
    co=CertificateOrder.find_by_ref(params[:certificate_order_id])
    result = co.apply_for_certificate
    co.certificate_content.pend_validation!(send_to_ca: false) if result.order_number && !co.certificate_content.pending_validation?
    respond_to do |format|
      format.js {render :json=>{:result=>render_to_string(:partial=>
          'sent_ca_result', locals: {ca_response: result})}}
    end
  end

  private

  def validation_stage_checkout_in_progress?
    co.certificate_content.contacts_provided?
  end

  def build_other_party_validation

  end

  def create_with_attachment file
    @val_history = ValidationHistory.new(:document => file)
    @certificate_order.validation.
      validation_histories << @val_history
    @val_history.save
    @val_history
  end

  def find_validation
    @validation=
        if params[:id]
          Validation.find(params[:id])
        elsif params[:certificate_order_id]
          CertificateOrder.find_by_ref(params[:certificate_order_id]).try(:validation)
        end
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
    @certificate_order = CertificateOrder.find_by_ref(params[:certificate_order_id])
    @validation = @certificate_order.validation if @certificate_order
  end

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
