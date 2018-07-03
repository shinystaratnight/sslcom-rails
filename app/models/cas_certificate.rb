class CasCertificate < ActiveRecord::Base
  STATUS = %w(default active inactive shadow hide)

  belongs_to :ca
  belongs_to :certificate
end



