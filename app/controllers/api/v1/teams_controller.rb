class Api::V1::TeamsController < Api::V1::APIController
  
  before_filter :has_api_access?
  
  def add_contact
    @result = CertificateContact.create(params
      .merge(contactable_id: @team.id, contactable_type: 'SslAccount')
      .permit(permit_contact_params)
    )
    render_200_status_noschema
  end
  
  private
  
  def permit_contact_params
    [
      :title,
      :first_name,
      :last_name,
      :company_name,
      :department,
      :po_box,
      :address1,
      :address2,
      :address3,
      :city,
      :state,
      :country,
      :postal_code,
      :email,
      :phone,
      :ext,
      :fax,
      :roles,
      :contactable_id,
      :contactable_type,
      roles: []
    ]
  end  
end