class SiteController < ApplicationController

  def index
    if current_subdomain==Reseller::SUBDOMAIN
      flash.now[:notice] ||= params[:notice]
      render  :action=>'reseller'
    end
  end

  def about
  end

  def help
  end

  def contact_us
  end

  def host_providers
  end
end
