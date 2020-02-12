# frozen_string_literal: true

class ApiUserRequest < CaApiRequest
  attr_accessor :test, :action, :admin_submitted

  CREATE_ACCESSORS_1_4 = %i[login email password first_name last_name phone organization 
                            address1 address2 address3 po_box postal_code city state country
                            account_key secret_key options account_number].freeze

  attr_accessor *(CREATE_ACCESSORS_1_4).uniq

  before_validation(on: :create) do
    if self.account_key && self.secret_key
      ac=ApiCredential.find_by_account_key_and_secret_key(self.account_key, self.secret_key)
      if ac.present?
        self.api_requestable = ac.ssl_account
      else
        errors[:login] << missing_account_key_or_secret_key
      end
    end
  end

  def find_user
    if defined?(:login) && self.login
      if self.api_requestable.users.find(&:is_admin?)
        self.admin_submitted = true
        if user=User.find_by_login(self.login)
          self.api_requestable = user.ssl_account
          user
        else
          errors[:user] << "User account not found for '#{self.login}'."
        end
      else
        self.api_requestable.certificate_orders.find_by_ref(self.ref) || (errors[:certificate_order] << "Certificate order not found for ref #{self.ref}.")
      end
    end
  end

  def login
    read_attribute(:login) || JSON.parse(self.parameters)["login"]
  end

  def retry
    %x"curl -k -H 'Accept: application/json' -H 'Content-type: application/json' -X #{request_method.upcase} -d '#{parameters}' #{request_url.gsub(".com",".local:3000").gsub("http:","https:")}"
  end
end
