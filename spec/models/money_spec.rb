describe Money, "overwritten version of #== since original threw errors on comparing non-money objects" do
  subject{Money.new(10)}
  it "should be false if equating to a non-money object" do
    (subject=="10").should be_false
    (subject==10).should be_false
  end

  it "should be false if equating to a different value money object" do
    #one way to do equals
    (subject==Money.new(11)).should be_false
  end

  it "should be true if equating to a same value money object" do
    #another way to do it
    subject.should == Money.new(10)
  end
end