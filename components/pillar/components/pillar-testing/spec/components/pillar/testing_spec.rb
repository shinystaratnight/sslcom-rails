# frozen_string_literal: true

module Pillar
  RSpec.describe Testing do
    describe "root path should return components root path" do
      it ".root" do
        puts Testing.root
        expect(Testing.root).to eq(Pathname.new(File.expand_path("../../..", __dir__)))
      end
    end
  end
end
