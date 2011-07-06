require 'open-uri'
require 'nokogiri'

class SurlsController < ApplicationController
  skip_filter   :record_visit
  after_filter  :record_surl_visit, only: [:show]

  # GET /surls
  # GET /surls.xml
  def index
    @surls=get_valid_surls
    @surl = Surl.new
  end

  # GET /surls/1
  # GET /surls/1.xml
  def show
    @render_result=Surl::RENDERED
    @surl = Surl.find_by_identifier(params[:id])
    not_found and return if @surl.blank?
    unless @surl.is_http?
      @render_result=Surl::REDIRECTED
      redirect_to @surl.original
    else
      if Malware.is_blacklisted?(@surl.original)
        @render_result=Surl::BLACKLISTED
        render action: "blacklisted", layout: false
      else
        begin
          doc = Nokogiri::HTML(open(@surl.original))
          doc.encoding = 'UTF-8' if doc.encoding.blank?
          head = doc.at_css "head"
          base = Nokogiri::XML::Node.new "base", doc
          base["href"]=@surl.original
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
          render inline: doc.to_html
        rescue Exception=>e
          logger.error("Error in SurlsController#show: #{e.message}")
          @render_result=Surl::REDIRECTED
          redirect_to @surl.original
        end
      end
    end
  end

  # GET /surls/new
  # GET /surls/new.xml
  def new
    @surl = Surl.new
  end

  # GET /surls/1/edit
  def edit
    @surl = Surl.find_by_guid(params[:id])
    render action: "edit"
  end

  # POST /surls
  # POST /surls.xml
  def create
    @surl = Surl.create(params[:surl])
    if @surl.errors.blank?
      add_link_to_cookie(@surl.guid)
      @surl_row = render_to_string("_surl_row.html.haml", layout: false, locals: {surl: @surl})
    end
    respond_to do |format|
      surl_js = @surl.errors.blank? ?  @surl.to_json.chop+", \"row\": #{@surl_row.to_json}}" : @surl.errors.to_json
      format.js {render(text: surl_js)}
    end
  end

  # PUT /surls/1
  # PUT /surls/1.xml
  def update
    @surl = Surl.find(params[:id])

    respond_to do |format|
      if @surl.update_attributes(params[:surl])
        format.html { redirect_to(@surl, :notice => 'Surl was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @surl.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /surls/1
  # DELETE /surls/1.xml
  def destroy
    @surl = Surl.find_by_guid(params[:id])
    @surl.destroy

    respond_to do |format|
      format.js { render text: @surl.to_json }
    end
  end

  private
  def add_link_to_cookie(guid)
    guids=get_guids
    guids << guid.to_s
    save_cookie name: :links, value: {guid: guids.compact.join(",")}, path: "/", expires: 2.years.from_now
  end

  def remove_link_from_cookie(guid)
    guids=get_guids
    unless guids.blank? || guids.include?(guid)
      guids.delete guid
    end
    save_cookie name: :links, value: {guid: guids.compact.join(",")}, path: "/", expires: 2.years.from_now
  end

  def get_valid_surls
    guids=get_guids
    unless guids.blank?
      guids.map do |g|
        surl=Surl.find_by_guid(g)
#        surl=Surl.joins(:surl_visits).where(:guid=>g)
        if surl.blank? || surl.status==Surl::REMOVE
          remove_link_from_cookie(g)
          nil
        else
          surl
        end
      end.compact
    else
      guids
    end
  end

  def get_guids
    links=get_cookie("links")
    guids=links.blank? ? [] : links["guid"].split(",")
  end

  def record_surl_visit
    SurlVisit.create visitor_token: @visitor_token,
                    surl: @surl,
                    referer_host: request.env['REMOTE_HOST'],
                    referer_address: request.env['REMOTE_ADDR'],
                    request_uri: request.env['REQUEST_URI'],
                    http_user_agent: request.env['HTTP_USER_AGENT'],
                    result: @render_result
  end
end
