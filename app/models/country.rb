class Country < ActiveRecord::Base
  BLACKLIST=%w(AF CU ER GN IR IQ LR KP RW SL SY SD SS ZW)
  PRIORITY = [["United States", "US"], ["United Kingdom", "UK"], ["Canada", "CA"]]

  scope :approved, ->{where{iso1_code << Country::BLACKLIST}}

  def to_param
    iso1_code
  end

  def self.iso1_codes
    select(:iso1_code).map(&:iso1_code)
  end

  def self.accepted_countries
    iso1_codes-BLACKLIST
  end
end
