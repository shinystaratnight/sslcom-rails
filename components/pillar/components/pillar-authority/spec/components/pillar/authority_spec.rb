module Pillar
  RSpec.describe Authority do
    describe "root path should return components root path" do
      it ".root" do
        puts Authority.root
        expect(Authority.root).to eq(Pathname.new(File.expand_path("../../..", __dir__)))
      end

      it ".version" do
        puts Authority.version
        expect(Authority.version).to eq(Authority::VERSION)
      end
    end
  end
end
