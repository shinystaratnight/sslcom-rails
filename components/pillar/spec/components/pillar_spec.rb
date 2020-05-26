RSpec.describe Pillar do
  describe "root path should return components root path" do
    it ".root" do
      puts Pillar.root
      expect(Pillar.root).to eq(Pathname.new(File.expand_path("../..", __dir__)))
    end
  end
end