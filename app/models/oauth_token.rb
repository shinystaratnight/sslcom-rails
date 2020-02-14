# == Schema Information
#
# Table name: oauth_tokens
#
#  id                    :integer          not null, primary key
#  authorized_at         :datetime
#  callback_url          :string(255)
#  invalidated_at        :datetime
#  scope                 :string(255)
#  secret                :string(40)
#  token                 :string(40)
#  type                  :string(20)
#  valid_to              :datetime
#  verifier              :string(20)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  client_application_id :integer
#  user_id               :integer
#
# Indexes
#
#  index_oauth_tokens_on_client_application_id  (client_application_id)
#  index_oauth_tokens_on_id_and_type            (id,type)
#  index_oauth_tokens_on_token                  (token) UNIQUE
#  index_oauth_tokens_on_user_id                (user_id)
#

class OauthToken < ApplicationRecord
  belongs_to :client_application
  belongs_to :user
  validates_uniqueness_of :token
  validates_presence_of :client_application, :token
  before_validation :generate_keys, :on => :create

  def invalidated?
    invalidated_at != nil
  end

  def invalidate!
    update_attribute(:invalidated_at, Time.now)
  end

  def authorized?
    authorized_at != nil && !invalidated?
  end

  def to_query
    "oauth_token=#{token}&oauth_token_secret=#{secret}"
  end

  protected

  def generate_keys
    self.token = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end
end
