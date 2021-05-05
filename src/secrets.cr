module Secrets
  protected def self.encrypt_data(data : String, environment : String) : String
    cipher = Secrets.new_cipher
    cipher.encrypt
    cipher.key = Secrets.key(environment)

    String.new(cipher.update(data)) + String.new(cipher.final)
  end

  protected def self.decrypt_data(data : String, environment : String) : String
    decipher = Secrets.new_cipher
    decipher.decrypt
    decipher.key = Secrets.key(environment)

    String.new(decipher.update(data)) + String.new(decipher.final)
  end

  protected def self.key(environment : String) : String
    path = "config/secrets/#{environment}.key"
    if File.exists?(path)
      File.read(path)
    else
      cipher = Secrets.new_cipher
      key = Random::Secure.hex(cipher.key_len)[0, cipher.key_len]
      File.write(path, key)
      key
    end
  end

  protected def self.new_cipher : OpenSSL::Cipher
    OpenSSL::Cipher.new("aes-256-cbc")
  end
end
