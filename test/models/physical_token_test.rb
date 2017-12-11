require "test_helper"

describe PhysicalToken do
  let(:physical_token) { PhysicalToken.new }

  it "must be valid" do
    value(physical_token).must_be :valid?
  end
end
