require 'rails_helper'

describe FundedAccountDecorator, type: :decorator do
  subject { described_class.new(FundedAccount.new) }

  it_behaves_like 'an ApplicationDecorator'

  it 'has an available amount of zero when initialized' do
    expect(subject.available).to eq '$0.00'
  end
end
