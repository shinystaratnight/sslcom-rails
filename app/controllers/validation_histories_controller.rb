class ValidationHistoriesController < ApplicationController
  before_action :find_validation_history, :only=>[:update]
  filter_access_to :documents, :require=>:read

  def update
    respond_to do |format|
      if @validation_history.update_attributes(params[:validation_history])
        #protected for admins only
        if current_user.is_admin?
          @validation_history.update_attribute(:publish_to_site_seal_approval,
            params[:validation_history][:publish_to_site_seal_approval]) if
              params[:validation_history][:publish_to_site_seal_approval]
          r = params[:validation_history][:validation_rules]
          unless r.blank?
            if r.include?(Validation::NONE_SELECTED)
              @validation_history.validation_rules.delete_all
            else
              r.each do |i|
                vr = ValidationRule.find(i)
                @validation_history.validation_rules << vr unless vr.blank? ||
                  @validation_history.validation_rules.include?(vr)
              end
            end
          end
          m = params[:validation_history][:satisfies_validation_methods]
          unless m.blank?
            m = nil if m.include?(Validation::NONE_SELECTED)
            @validation_history.
              update_attribute :satisfies_validation_methods, m
          end
        end
        format.js { render :json=>@validation_history.to_json}
      else
        format.js { render :json=>@validation_history.errors.to_json}
      end
    end
  end

  def index
    @validation_histories=(current_user.is_system_admins? ? ValidationHistory : current_user.validation_histories).all
    respond_to do |format|
      format.html { render :action => :index }
    end
  end
    
  def documents
    vh = if params[:registrant]
      r = Registrant.find_by(id: params[:registrant])
      r.validation_histories.find_by(id: params[:id])
    else
      (current_user.is_system_admins? ? ValidationHistory : current_user.validation_histories).find(params[:id])
    end
    if vh
      # => Use this if we want to store to the file system instead of s3.
      # Comment out the redirecto_to
#      send_file vh.document.path(params['style'].to_sym),
#        :type => vh.document.content_type, :disposition => 'attachment'
      if vh.document_file_name.force_encoding('UTF-8').include? (params['style']+'.'+params['extension']) #files with multiple .'s present a problem'
        style = vh.document.default_style
      else
        style = params['style'].to_sym
      end
      redirect_to vh.authenticated_s3_get_url :style=> style
    else
      render :status=>403
    end
  end

  private

  def find_validation_history
    if params[:id]
      @validation_history=ValidationHistory.find(params[:id])
    end
  end
end
