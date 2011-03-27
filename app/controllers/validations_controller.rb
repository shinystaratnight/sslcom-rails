open3 = "open3"
open3.insert(0,'win32/') if RUBY_PLATFORM =~ /mswin32/
require open3
require 'zip/zipfilesystem'
require 'tempfile'
include Open3

class ValidationsController < ApplicationController
  before_filter :find_validation, :only=>[:update]
  filter_access_to :upload, :require=>:create
  filter_access_to :all
  filter_access_to :requirements, :domain_control, :ev, :organization, require: :read
  filter_access_to :update, :edit, :attribute_check=>false
  in_place_edit_for :validation_history, :notes

  def new
    @certificate_order = CertificateOrder.find_by_ref(params[:certificate_order_id])
  end

  def edit
    @certificate_order = CertificateOrder.find_by_ref(params[:certificate_order_id])
  end

  def search
    index
  end

  def index
    p = {:page => params[:page]}
    @certificate_orders =
      if @search = params[:search]
       current_user.is_admin? ?
        CertificateOrder.search(params[:search]).find_unvalidated :
        current_user.ssl_account.certificate_orders.
          search(params[:search]).find_unvalidated
      else
        current_user.is_admin? ?
          CertificateOrder.find_unvalidated :
            current_user.ssl_account.certificate_orders.unvalidated
      end.paginate(p)
    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def show
    @certificate_order = CertificateOrder.find_by_ref(params[:certificate_order_id])
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

  def upload
    i=0
    error=""
    @zip_file_name = ""
    @certificate_order = CertificateOrder.find_by_ref(params[:certificate_order_id])
    @files = params[:filedata]
    if @files.blank?
      error = 'Please select one or more files to upload.'
    else
      @files.each do |file|
        @created_releases = []
        if (file.respond_to?(:content_type) && file.content_type.include?("zip")) ||
            (file.respond_to?(:original_filename) && file.original_filename.include?("zip"))
          logger.info "creating directory #{RAILS_ROOT}/tmp/zip/temp"
          FileUtils.mkdir_p "#{RAILS_ROOT}/tmp/zip/temp" if !File.exist?("#{RAILS_ROOT}/tmp/zip/temp")
          if file.size > Settings.max_content_size.to_i.megabytes
            break error = <<-EOS
              Too Large: zip file #{file.original_filename} is larger than
              #{help.number_to_human_size(Settings.max_content_size.to_i.megabytes)}
            EOS
          end
          @zip_file_name=file.original_filename
          File.open("#{RAILS_ROOT}/tmp/zip/#{file.original_filename}", "wb") do |f|
            f.write(file.read)
          end
          zf = Zip::ZipFile.open("#{RAILS_ROOT}/tmp/zip/#{file.original_filename}")
          if zf.size > Settings.max_num_releases.to_i
            break error = <<-EOS
              Too Many Files: zip file #{file.original_filename} contains more than
              #{Settings.max_num_releases.to_i} files.
            EOS
          end
          zf.each do |entry|
            begin
              fpath = File.join("#{RAILS_ROOT}/tmp/zip/temp/",entry.name.downcase)
              if(File.exists?(fpath))
                File.delete(fpath)
              end
              zf.extract(entry, fpath)
              @created_releases << create_with_attachment(LocalFile.new(fpath))
              i+=1
            rescue Errno::ENOENT, Errno::EISDIR
              error = "Invalid contents: zip entries with directories not allowed".l
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
          vh = create_with_attachment LocalFile.new(file.path,
            file.original_filename)
          vh.errors.each{|attr,msg|
            error << "#{attr} #{msg}: " }
          i+=1 if vh
          error << "Error: Document for #{file.original_filename} was not
            created. Please notify system admin at #{Settings.support_email}" unless vh
        end
      end
    end
    respond_to do |format|
      if error.blank?
        files_were = (i > 1 or i==0)? "documents were" : "document was"
        flash[:notice] = "#{i.in_words.capitalize} (#{i}) #{files_were}
          successfully saved."
        @certificate_order.certificate_content.pend_validation! if
          @certificate_order.certificate_content.contacts_provided?
        @validation_histories = @certificate_order.validation_histories
        format.html { redirect_to edit_certificate_order_validation_path}
        format.xml { render :xml => @release,
          :status => :created,
          :location => @release }
      else
        flash[:error] = error
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

  private

  def create_with_attachment file
    @val_history = ValidationHistory.new(:document => file)
    @certificate_order.validation.
      validation_histories << @val_history
    @val_history.save
    @val_history
  end

  def find_validation
    if params[:id]
      @validation=Validation.find(params[:id])
    end
  end

  def notify_customer(validation_rulings)
    recips = [@co.certificate_content.administrative_contact]
    recips << @co.certificate_content.validation_contact unless
      @co.certificate_content.validation_contact==
      @co.certificate_content.administrative_contact
    recips.each do |c|
      if validation_rulings.all?(&:approved?)
        OrderNotifier.deliver_validation_approve(c, @co)
      else
        OrderNotifier.deliver_validation_unapprove(c, @co, @validation)
      end
    end
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
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
  end
end
