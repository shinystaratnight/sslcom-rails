require 'rest-client'
require 'base64'
require 'pp'
require 'airbrake/delayed_job'

class PopulateDunsJob < Struct.new(:duns_number, :locked_registrant_id)
  def perform
    client = RegistrationAuthority::DnB::Client.new(
      api_key: ENV["DUNS_API_KEY"], 
      api_secret: ENV["DUNS_API_SECRET"]
    )

    access_token = client.api_token
    organization = client.organization.find(id: duns_number)

    if organization
      organization_status = organization&.duns_control_status&.operating_status["dnbCode"]
      locked_registrant   = LockedRegistrant.find(locked_registrant_id)

      if organization_status == 9074 && (locked_registrant&.status == "in_progress" || locked_registrant&.status.nil?)
        locked_registrant.update_attributes(organization.to_struct.to_h)

        if locked_registrant.save!
          SystemAudit.create(
            owner:  nil,
            target: locked_registrant,
            notes:  "Updated locked registrant from duns API",
            action: "Automated DUNs API Update Success"
          )
        else
          SystemAudit.create(
            owner:  nil,
            target: locked_registrant,
            notes:  "Updated locked registrant from duns API Failed",
            action: "Automated DUNs API Update Failure"
          )
        end
      end
    end
  end
end
