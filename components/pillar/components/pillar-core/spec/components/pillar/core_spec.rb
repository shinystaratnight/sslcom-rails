# frozen_string_literal: true

module Pillar
  RSpec.describe Core do
    describe "root path should return components root path" do
      it ".root" do
        puts Core.root
        expect(Core.root).to eq(Pathname.new(File.expand_path("../../..", __dir__)))
      end
    end
  end
end
