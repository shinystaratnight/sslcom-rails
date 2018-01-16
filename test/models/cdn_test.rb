require "test_helper"

describe Cdn do
  let(:cdn) { Cdn.new }

  it "must be valid" do
    value(cdn).must_be :valid?
  end
end
