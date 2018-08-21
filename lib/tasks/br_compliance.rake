namespace :validation_compliances do
  desc "Domain Control Validation Compliance Mappings"
  task seed_validation_compliances: :environment do
    if ENV['RESET']
      ValidationCompliance.delete_all
    end
    ValidationCompliance.create!([{
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.1",
                      description: "Validating the Applicant as a Domain Contact"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.2",
                      description: "Email, Fax, SMS, or Postal Mail to Domain Contact"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.3",
                      description: "Phone Contact with Domain Contact"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.4",
                      description: "Constructed Email to Domain Contact"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.5",
                      description: "Domain Authorization Document"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.6",
                      description: "Agreed-Upon Change to Website"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.7",
                      description: "DNS Change"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.8",
                      description: "IP Address"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.9",
                      description: "Test Certificate"
                  },
                  {
                      document: "Baseline Requirements",
                      version: "1.6.0",
                      section: "3.2.2.4.10",
                      description: "TLS Using a Random Number"
                  }])
  end
end
