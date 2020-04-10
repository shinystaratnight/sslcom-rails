# frozen_string_literal: true

# == Schema Information
#
# Table name: server_softwares
#
#  id          :integer          not null, primary key
#  support_url :string(255)
#  title       :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#
FactoryBot.define do
  factory :server_software do
  end
end
