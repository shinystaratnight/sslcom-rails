require 'rails_helper'

describe Cdn do
  it { is_expected.to belong_to(:ssl_account) }
  it { is_expected.to belong_to(:certificate_order) }
end
