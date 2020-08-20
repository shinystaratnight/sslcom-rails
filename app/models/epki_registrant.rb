class EpkiRegistrant < Registrant
  alias_attribute :constraints, :domains

end
