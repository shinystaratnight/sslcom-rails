class LockedRegistrant < Registrant
  serialize :domains
  alias_attribute :constraints, :domains
end