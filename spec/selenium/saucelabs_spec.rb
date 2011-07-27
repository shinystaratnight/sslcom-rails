require "spec_helper"

describe "my app" do
  it "should have a home page" do
    page.open "/"
    page.is_text_present("certificates").should be_true
  end
end