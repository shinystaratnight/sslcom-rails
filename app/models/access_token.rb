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

class AccessToken < OauthToken
  validates_presence_of :user, :secret
  before_create :set_authorized_at

  # Implement this to return a hash or array of the capabilities the access token has
  # This is particularly useful if you have implemented user defined permissions.
  # def capabilities
  #   {:invalidate=>"/oauth/invalidate",:capabilities=>"/oauth/capabilities"}
  # end

  protected

  def set_authorized_at
    self.authorized_at = Time.now
  end
end
