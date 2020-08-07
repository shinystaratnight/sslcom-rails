class U2f < ApplicationRecord
  belongs_to :user

  validates :nick_name, :key_handle, presence: true
end
