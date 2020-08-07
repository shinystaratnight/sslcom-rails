# frozen_string_literal: true
require 'rails_helper'

describe PhysicalToken do
  it { is_expected.to have_db_column :activation_pin }
  it { is_expected.to have_db_column :admin_pin }
  it { is_expected.to have_db_column :license }
  it { is_expected.to have_db_column :management_key }
  it { is_expected.to have_db_column :manufacturer }
  it { is_expected.to have_db_column :model_number }
  it { is_expected.to have_db_column :name }
  it { is_expected.to have_db_column :notes }
  it { is_expected.to have_db_column :serial_number }
  it { is_expected.to have_db_column :shipping_method }
  it { is_expected.to have_db_column :tracking_number }
  it { is_expected.to have_db_column :workflow_state }
  it { is_expected.to have_db_column :created_at }
  it { is_expected.to have_db_column :updated_at }
  it { is_expected.to have_db_column :certificate_order_id }
  it { is_expected.to have_db_column :signed_certificate_id }
end
