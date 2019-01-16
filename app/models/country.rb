class Country < ActiveRecord::Base
  BLACKLIST=%w(AF CU ER GN IR IQ LR KP RW SL SY SD SS ZW)
  PRIORITY = [["United States", "US"], ["United Kingdom", "GB"], ["Canada", "CA"]]

  scope :approved, ->{where{iso1_code << Country::BLACKLIST}}

  def to_param
    Rails.cache.fetch("#{cache_key}/to_param") do
      iso1_code
    end
  end

  def self.iso1_codes
    Rails.cache.fetch("Country/iso1_codes") do
      select(:iso1_code).map(&:iso1_code)
    end

  end

  def self.accepted_countries
    Rails.cache.fetch("Country/accepted_countries") do
      iso1_codes-BLACKLIST
    end
  end
end
