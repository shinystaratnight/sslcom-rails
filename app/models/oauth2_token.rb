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

class Oauth2Token < AccessToken
  attr_accessor :state
  def as_json(options={})
    d = {:access_token=>token, :token_type => 'bearer'}
    d[:expires_in] = expires_in if expires_at
    d
  end

  def to_query
    q = "access_token=#{token}&token_type=bearer"
    q << "&state=#{URI.escape(state)}" if @state
    q << "&expires_in=#{expires_in}" if expires_at
    q << "&scope=#{URI.escape(scope)}" if scope
    q
  end

  def expires_in
    expires_at.to_i - Time.now.to_i
  end
end
