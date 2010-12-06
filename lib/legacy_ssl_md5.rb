class LegacySslMd5
  def self.encrypt(*tokens)
    i=tokens
    # the tokens passed will be an array of objects, what type of object is irrelevant,
    # just do what you need to do with them and return a single encrypted string.
    # for example, you will most likely join all of the objects into a single string and then encrypt that string
  end

  def self.matches?(crypted, *tokens)
    # return true if the crypted string matches the tokens.
    # depending on your algorithm you might decrypt the string then compare it to the token, or you might
    # encrypt the tokens and make sure it matches the crypted string, its up to you
    hash_with_salt = Base64.decode64 crypted
    salt = hash_with_salt[0..(hash_with_salt.size-16-1)]
    plain_pwd=tokens[0]
    d = Digest::MD5.digest salt+plain_pwd
    hash_with_salt==salt+d
  end
end

