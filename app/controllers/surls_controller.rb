require 'open-uri'
require 'nokogiri'

class SurlsController < ApplicationController

  # GET /surls
  # GET /surls.xml
  def index
    @surl = Surl.new
  end

  # GET /surls/1
  # GET /surls/1.xml
  def show
    @surl = Surl.find(params[:id].to_i(36))
    unless @surl.is_http?
      redirect_to @surl.original
    else
      if Malware.is_blacklisted?(@surl.original)
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
        rescue
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
    @surl = Surl.find(params[:id])
  end

  # POST /surls
  # POST /surls.xml
  def create
    @surl = Surl.create(params[:surl])
    add_link_to_cookie(@surl) if @surl.errors.blank?
    respond_to do |format|
      format.js {render(text: @surl.to_json)}
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
    @surl = Surl.find(params[:id])
    @surl.destroy

    respond_to do |format|
      format.html { redirect_to(surls_url) }
      format.xml  { head :ok }
    end
  end

  private
  def add_link_to_cookie(surl)
    links=get_cookie("links")
    guids=links.blank? ? [] : links["guid"].split(",")
    guids << surl.guid
    save_cookie name: :links, value: {guid: guids.compact.join(",")}, path: "/", expires: 2.years.from_now
  end
end
