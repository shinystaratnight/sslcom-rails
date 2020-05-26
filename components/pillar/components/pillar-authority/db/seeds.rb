ActiveRecord::Base.transaction do
  Dir[File.join(Pillar::Authority.root, "db", "seeds", "**", "*.rb")].sort.each do |seed|
    load seed
  end
end
