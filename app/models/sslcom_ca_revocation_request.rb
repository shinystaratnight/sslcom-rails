# This class represent revocations requests sent to the SSL.com CA. It's assumed the content-type is JSON

class SslcomCaRevocationRequest < CaApiRequest
  REASONS = %w(UNSPECIFIED  KEYCOMPROMISE  CACOMPROMISE  AFFILIATIONCHANGED  SUPERSEDED  CESSATIONOFOPERATION
            CERTIFICATEHOLD  REMOVEFROMCRL  PRIVILEGESWITHDRAWN  AACOMPROMISE)

end