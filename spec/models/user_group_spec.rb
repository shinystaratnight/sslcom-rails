# == Schema Information
#
# Table name: user_groups
#
#  id             :integer          not null, primary key
#  description    :text(65535)
#  name           :string(255)
#  notes          :text(65535)
#  roles          :string(255)      default("--- []")
#  ssl_account_id :integer
#
# Indexes
#
#  index_user_groups_on_ssl_account_id  (ssl_account_id)
#
require 'rails_helper'

RSpec.describe UserGroup, type: :model do
  it_behaves_like 'it has roles'
end
