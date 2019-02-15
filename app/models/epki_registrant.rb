class EpkiRegistrant < Registrant
  serialize :domains
  alias_attribute :constraints, :domains
end