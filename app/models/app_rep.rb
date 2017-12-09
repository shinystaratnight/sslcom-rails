class AppRep < Contact

  belongs_to :ssl_account

  CALLBACK_METHODS=['t','l']
  validates :callback_method,
            inclusion: {in: CALLBACK_METHODS,
                        message: "needs to one of the following: #{CALLBACK_METHODS}"}
  validate  :phone, if: lambda{|a|a.callback_method=='t'}
end
