class Country < ActiveRecord::Base
  BLACKLIST=%w(AF BY  CI  CU  ER  GN  IR  IQ  LB  LR  MM  KP  PK  RW  SL  SY  SD  SS  ZW)

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
