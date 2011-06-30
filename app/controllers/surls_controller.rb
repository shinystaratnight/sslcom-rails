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
      doc = Nokogiri::HTML(open(@surl.original))
      head = doc.at_css "head"
      base = Nokogiri::XML::Node.new "base", doc
      base["href"]=@surl.original
      body = doc.at_css "body"
      div = Nokogiri::XML::Node.new "div", doc
      div["style"] = "background:#fff;border:1px solid #999;margin:-1px -1px 0;padding:0;"
      div.inner_html = render_to_string(partial: "d", layout: false)
      body.children.first.before(div)
      head.children.first.before(base)
      render inline: doc.to_html
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
end
