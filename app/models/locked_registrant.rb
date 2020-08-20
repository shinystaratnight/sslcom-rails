class LockedRegistrant < Registrant
  serialize :domains
  alias_attribute :constraints, :domains

  before_update :update_duns, if: :duns_number_changed?
  before_create :update_duns

  def update_duns
    PopulateDunsJob.new(duns_number, id).perform if duns_number && duns_number != ""
  end
end
