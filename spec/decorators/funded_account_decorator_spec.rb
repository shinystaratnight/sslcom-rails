require 'rails_helper'

describe FundedAccountDecorator, type: :decorator do
  subject { described_class.new(FundedAccount.new) }

  it 'has an available amount of zero when initialized' do
    expect(subject.available).to eq 0
  end
end
