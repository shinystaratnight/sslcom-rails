#only required if we use Base64 (see below)
require 'digest'
require 'openssl'
require 'base64'

class LegacySslSha1
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
    #Ruby 1.8 version - faster but I haven't gotten it to work
#    hash_with_salt = Base64.decode64 crypted
    hash_with_salt = crypted.unpack('m')[0]
    salt = hash_with_salt[0..(hash_with_salt.size-16-1)]
    plain_pwd=tokens[0]
    d = Digest::MD5.digest salt+plain_pwd
    hash_with_salt==salt+d

    crypted="8773732869"
    hash_bytes = crypted.unpack('m')[0]
    sha = Digest::SHA1.digest hash_bytes
    key = sha[0..(sha.size-8)]
    iv = sha[9..sha.size]
    message = "2d2am+n5hy+5Unr1Q3fAIuqwKXQP0k+t"

    # Encrypt plaintext using Triple DES
    cipher = OpenSSL::Cipher::Cipher.new("des3")
    cipher.encrypt # Call this before setting key or iv
    cipher.key = key
    cipher.iv = iv
    ciphertext = cipher.update(message)
    ciphertext << cipher.final

    puts "Encrypted \"#{message}\" with \"#{key}\" to:\n\"#{ciphertext}\"\n"

    # Base64-encode the ciphertext
    encodedCipherText = Base64.encode64(ciphertext)

    # Base64-decode the ciphertext and decrypt it
    cipher.decrypt
    plaintext = cipher.update(Base64.decode64(encodedCipherText))
    plaintext << cipher.final

    # Print decrypted plaintext; should match original message
    puts "Decrypted \"#{ciphertext}\" with \"#{key}\" to:\n\"#{plaintext}\"\n\n"

  end

  def self.test
    plain_key="8773732869"
    message = Base64.decode64 "2d2am+n5hy+5Unr1Q3fAIuqwKXQP0k+t"
    hash_bytes = Base64.encode64 plain_key
    hash_bytes = plain_key.unpack('m')[0]
    sha = Digest::SHA1.digest hash_bytes
    key = sha[0..7]
    iv = sha[8..15]

    # Encrypt plaintext using Triple DES
    cipher = OpenSSL::Cipher::Cipher.new("des")
    cipher.decrypt # Call this before setting key or iv
    cipher.key = key
    cipher.iv = iv
    ciphertext = cipher.update(message)
    ciphertext << cipher.final
  end
end

