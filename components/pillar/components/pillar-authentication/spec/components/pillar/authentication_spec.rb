module Pillar
  RSpec.describe Authentication do
    describe "root path should return components root path" do
      it ".root" do
        puts Authentication.root
        expect(Authentication.root).to eq(Pathname.new(File.expand_path("../../..", __dir__)))
      end
    end
  end
end
