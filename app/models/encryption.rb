module Encryption
  mattr_accessor :algorithm
  self.algorithm = 'aes-256-cbc'
  
  def encrypt(data, password, salt)
    cipher = OpenSSL::Cipher::Cipher.new(algorithm)
    cipher.encrypt
    cipher.pkcs5_keyivgen(password, salt)
    encrypted_data = cipher.update(data)
    encrypted_data << cipher.final
  end
  
  def decrypt(encrypted_data, password, salt)
    cipher = OpenSSL::Cipher::Cipher.new(algorithm)
    cipher.decrypt
    cipher.pkcs5_keyivgen(password, salt)
    data = cipher.update(encrypted_data)
    data << cipher.final
  end
  
end