class DuplicateV2User < ActiveRecord::Base
  belongs_to  :user
  has_many    :legacy_v2_user_mappings, :as=>:user_mappable

  def self.find_and_notify(params)
    if dup = find_by_login(params[:login]) || find_by_email(params[:email])
      DuplicateV2UserMailer.duplicate_found(dup).deliver!
    else
      false
    end
  end
end
