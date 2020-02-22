# frozen_string_literal: true

# == Schema Information
#
# Table name: websites
#
#  id          :integer          not null, primary key
#  api_host    :string(255)
#  description :string(255)
#  host        :string(255)
#  name        :string(255)
#  type        :string(255)
#  db_id       :integer
#
# Indexes
#
#  index_websites_on_db_id        (db_id)
#  index_websites_on_id_and_type  (id,type)
#


class Sandbox < Website
  def self.exists?(domain = '')
    return false if domain.blank?

    Rails.cache.fetch("Sandbox.exists/#{domain}", expires_in: 24.hours) do
      where{ (host == domain) | (api_host == domain) }.present?
    end
  end
end
