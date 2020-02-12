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

class RequestToken < OauthToken

  attr_accessor :provided_oauth_verifier

  def authorize!(user)
    return false if authorized?
    self.user = user
    self.authorized_at = Time.now
    self.verifier=OAuth::Helper.generate_key(20)[0,20] unless oauth10?
    self.save
  end

  def exchange!
    return false unless authorized?
    return false unless oauth10? || verifier==provided_oauth_verifier

    RequestToken.transaction do
      access_token = AccessToken.create(:user => user, :client_application => client_application)
      invalidate!
      access_token
    end
  end

  def to_query
    if oauth10?
      super
    else
      "#{super}&oauth_callback_confirmed=true"
    end
  end
  
  def oob?
    callback_url.nil? || callback_url.downcase == 'oob'
  end

  def oauth10?
    (defined? OAUTH_10_SUPPORT) && OAUTH_10_SUPPORT && self.callback_url.blank?
  end

end
