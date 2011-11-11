class CsrsController < ApplicationController
  filter_access_to :all, :attribute_check=>true
  filter_access_to :country_codes, :require=>[:create] #anyone can create read creates csrs, thus read this

  # PUT /csrs/1
  # PUT /csrs/1.xml
  def update
    respond_to do |format|
      if @csr.update_attributes(params[:csr])
        flash[:notice] = 'Certificate was successfully updated.'
        format.html { redirect_to(@csr.certificate_content.certificate_order) }
        format.xml  { head :ok }
        format.js   { render :json=>@csr.to_json(:include=>:signed_certificate)}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @csr.errors, :status => :unprocessable_entity }
        format.js   { render :json=>@csr.errors.to_json}
      end
    end
  end

end
