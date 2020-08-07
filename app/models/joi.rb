class Joi < Contact

  belongs_to :ssl_account

  BUSINESS_CATEGORY = {b: "Private Organization", c: "Government Entity", d: "Business Entity", e: "Non-Commercial  Entity"}
  
  validates :city, :state, :country, :incorporation_date, :assumed_name, presence: true
  validates :business_category, presence: true,
            inclusion: {in: BUSINESS_CATEGORY.values,
                        message: "needs to one of the following: #{BUSINESS_CATEGORY.values.join(', ')}"}

end
