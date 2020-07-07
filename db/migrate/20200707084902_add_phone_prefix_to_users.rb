class AddPhonePrefixToUsers < ActiveRecord::Migration
  def change
    add_column :users, :phone_prefix, :string


    User.all.each do |user|
      next unless user.country.present? && user.phone.present?
      user_country = ISO3166::Country.find_country_by_name(user.country)
      user.phone_prefix = user_country.country_code
      user.save
    end
  end
end
