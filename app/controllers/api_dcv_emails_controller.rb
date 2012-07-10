class ApiDcvEmailsController < ApplicationController
  skip_filter :identify_visitor, :record_visit

  wrap_parameters ApiDcvEmails, include: [*ApiDcvEmails::ACCESSORS]
  respond_to :xml, :json

  SUBDOMAIN = "sws"

  def create_v1_3
    @api_dcv_emails=ApiDcvEmails.new(params[:api_dcv_emails])
    @api_dcv_emails.ca = 'ssl.com'
    if @api_dcv_emails.save
      @api_dcv_emails.email_addresses=ComodoApi.domain_control_email_choices(@api_dcv_emails.domain_name).email_address_choices
      unless @api_dcv_emails.email_addresses.blank?
        render(:template => "api_dcv_emails/success_create_v1_3")
      end
    else
      InvalidApiDcvEmails.create parameters: params, ca: "ssl.com"
    end
  end
end
