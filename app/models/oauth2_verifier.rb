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

class Oauth2Verifier < OauthToken
  validates_presence_of :user
  attr_accessor :state

  def exchange!(params={})
    OauthToken.transaction do
      token = Oauth2Token.create! :user=>user,:client_application=>client_application, :scope => scope
      invalidate!
      token
    end
  end

  def code
    token
  end

  def redirect_url
    callback_url
  end

  def to_query
    q = "code=#{token}"
    q << "&state=#{URI.escape(state)}" if @state
    q
  end

  protected

  def generate_keys
    self.token = OAuth::Helper.generate_key(20)[0,20]
    self.expires_at = 10.minutes.from_now
    self.authorized_at = Time.now
  end

end
