puts "\r\n[Pillar] Planting Seeds ....\r\n"

ActiveRecord::Base.transaction do
  Pillar::Authentication::Engine.load_seed
  Pillar::Authority::Engine.load_seed
  Pillar::Core::Engine.load_seed
  Pillar::Pages::Engine.load_seed
  Pillar::Theme::Engine.load_seed
end

puts "\r\n[Pillar] Harvest Complete ....\r\n\r\n"
