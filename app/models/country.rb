class Country < ActiveRecord::Base
  def to_param
    iso1_code
  end
end
