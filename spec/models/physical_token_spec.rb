# frozen_string_literal: true

# == Schema Information
#
# Table name: physical_tokens
#
#  id                    :integer          not null, primary key
#  activation_pin        :string(255)
#  admin_pin             :string(255)
#  license               :string(255)
#  management_key        :string(255)
#  manufacturer          :string(255)
#  model_number          :string(255)
#  name                  :string(255)
#  notes                 :text(65535)
#  serial_number         :string(255)
#  shipping_method       :string(255)
#  tracking_number       :string(255)
#  workflow_state        :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  certificate_order_id  :integer
#  signed_certificate_id :integer
#
# Indexes
#
#  index_physical_tokens_on_certificate_order_id   (certificate_order_id)
#  index_physical_tokens_on_signed_certificate_id  (signed_certificate_id)
#

require 'rails_helper'

describe PhysicalToken do
  it { should have_db_column :activation_pin }
  it { should have_db_column :admin_pin }
  it { should have_db_column :license }
  it { should have_db_column :management_key }
  it { should have_db_column :manufacturer }
  it { should have_db_column :model_number }
  it { should have_db_column :name }
  it { should have_db_column :notes }
  it { should have_db_column :serial_number }
  it { should have_db_column :shipping_method }
  it { should have_db_column :tracking_number }
  it { should have_db_column :workflow_state }
  it { should have_db_column :created_at }
  it { should have_db_column :updated_at }
  it { should have_db_column :certificate_order_id }
  it { should have_db_column :signed_certificate_id }
end
