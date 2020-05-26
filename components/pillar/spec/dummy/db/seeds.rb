ActiveRecord::Base.transaction do
  Pillar::Engine.load_seed
end
