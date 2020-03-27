require 'open-uri'
require 'nokogiri'
require 'timeout'

class SurlsController < ApplicationController
  before_action :find_surl_by_identifier, only: [:show, :login]
  before_action :find_surl_by_guid, only: [:edit, :destroy, :update]
  skip_before_action   :record_visit
  after_filter  :record_surl_visit, only: [:show]
  filter_access_to  :edit, :destroy, :update, attribute_check: true
  filter_access_to  :admin_index

  # GET /surls
  # GET /surls.xml
  def index
    p = {:page => params[:page]}
    if current_user && current_user.is_admin?
      @surls=Surl.paginate(p)
    else
      @surls=get_valid_surls(p)
    end
    @surl=Surl.new
  end

  def admin_index
    p = {:page => params[:page]}
    @surls=Surl.all.paginate(p)
    render action: index
  end

  #POST /surl_login
  def login
    @tmp_surl = Surl.new(params[:surl])
    @tmp_surl.set_access_restrictions = "1" #activates validations
    if @tmp_surl.valid?
      show
    else
      render action: "restricted", layout: "only_scripts_and_css"
    end
  end

  # GET /surls/1
  # GET /surls/1.xml
  def show
    @render_result=Surl::RENDERED
    not_found and return if @surl.blank?
    if @surl.username && @surl.password_hash && (@tmp_surl.blank? || !@surl.access_granted(@tmp_surl))
      @tmp_surl.errors[:base]<< "permission denied: invalid username and/or password" unless @tmp_surl.blank?
      render action: "restricted", layout: "only_scripts_and_css" and return
    end
    if !@surl.is_http? || !@surl.share ||
        (@surl.uri=~Regexp.new("\\.(#{Surl::REDIRECT_FILES.join("|")})$", "i")) || Settings.disable_links_banner
      @render_result=Surl::REDIRECTED
      redirect_to @surl.uri
    #elsif @surl.require_ssl && !request.ssl?
    #  @render_result=Surl::REDIRECTED
    #  redirect_to @surl.full_link
    else
      #disable until we can improve performance
      if false #Malware.is_blacklisted?(@surl.uri)
        @render_result=Surl::BLACKLISTED
        render action: "blacklisted", layout: false
      elsif %w(\.youtube\. \.paypal\. \.google\.).detect{|h|URI.parse(@surl.uri).host =~ Regexp.new(h, "i")}
        #retries = Surl::RETRIES
        begin
          timeout(Surl::TIMEOUT_DURATION) do
            #don't have time to finish this but should'
            #inner_html = render_to_string(partial: "banner", layout: false)
            #render inline: open(@surl.uri).read.sub(/(\<[^\/]*body[^\/]*?\>)/i, "\1#{inner_html}") #doc.to_html
            ###################
            doc = Nokogiri::HTML(open(@surl.uri))
            doc.encoding = 'UTF-8' if doc.encoding.blank?
            head = doc.at_css "head"
            base = Nokogiri::XML::Node.new "base", doc
            base["href"]=@surl.uri
            body = doc.at_css "body"
            div_position = Nokogiri::XML::Node.new('div', doc)
            div_position["style"] = "position: relative;"
            body.children.each do |child|
              child.parent = div_position
            end
            body.add_child(div_position)
            div = Nokogiri::XML::Node.new "div", doc
            div["style"] = "background:#fff;border:1px solid #999;margin:-1px -1px 0;padding:0;"
            div.inner_html = render_to_string(partial: "banner", layout: false)
            body.children.first.before(div)
            head.children.first.before(base)
            render(inline: doc.to_html) and return
          end
        #rescue OpenURI::HTTPError
        #  render status: 408
        #rescue Timeout::Error
        #  retries-=1
        #  if retries < Surl::RETRIES
        #    render status: 408
        #  else
        #    retry
        #  end
        rescue Exception=>e
          logger.error("Error in SurlsController#show: #{e.message}")
          @render_result=Surl::REDIRECTED
          redirect_to @surl.uri and return
        end
      end
      response.headers['X-Frame-Options'] = "SAMEORIGIN"
      render(action: "show", layout: false) and return
    end
  end

  # GET /surls/new
  # GET /surls/new.xml
  def new
    @surl = Surl.new
  end

  # GET /surls/1/edit
  def edit
    render action: "edit"
  end

  # POST /surls
  # POST /surls.xml
  def create
    @surl = Surl.new(params[:surl])
    @surl.user=current_user unless current_user.blank?
    @surl.save
    if @surl.errors.blank?
      add_link_to_cookie(@surl.guid)
      @surl_row = render_to_string("_surl_row.html.haml", layout: false, locals: {surl: @surl})
    end
    respond_to do |format|
      surl_js = @surl.errors.blank? ?  @surl.to_json.chop+", \"row\": #{@surl_row.to_json}}" : @surl.errors.to_json
      format.js {render(json: surl_js)}
    end
  end

  # PUT /surls/1
  # PUT /surls/1.xml
  def update
    respond_to do |format|
      if @surl.update_attributes(params[:surl])
        #would have liked to use the bottom link but the flash notice disappears by the time it hits the index action
        format.html { redirect_to surls_root_path,
          :notice=> "Link #{@surl.full_link} has been updated."}
        #flash[:notice]="Link #{@surl.full_link} has been updated."
        #index
        #format.html { render action: "index" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @surl.errors, :status => :unprocessable_entity }
      end
    end
  end

  def status_204
    render inline: "", status: 204
  end

  # DELETE /surls/1
  # DELETE /surls/1.xml
  def destroy
    @surl.destroy
    flash[:notice] = "Link #{@surl.full_link} has been deleted." if request.xhr?

    respond_to do |format|
      format.js   { render text: @surl.to_json }
      format.html { redirect_to surls_root_url(:subdomain=>Surl::SUBDOMAIN) }
    end
  end

  def disclaimer
    render action: 'disclaimer', layout: 'only_scripts_and_css'
  end

  private

  def find_surl_by_guid
    @surl = Surl.find_by_guid(params[:id])
  end

  def find_surl_by_identifier
    @surl = Surl.first(:conditions => ['BINARY identifier = ?', params[:id]])
  end
end
