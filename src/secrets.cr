require "openssl"
require "base64"
require "yaml"

module Secrets
  def self.read_yaml(environment : String) : YAML::Any
    YAML.parse Secrets.read(environment)
  end

  def self.read(environment : String) : String
    path = Secrets.data_path(environment)
    if File.exists?(path)
      encrypted = File.read(path)
      Secrets.decrypt_data(encrypted, environment)
    else
      ""
    end
  end

  def self.write(data : String, environment : String) : Nil
    path = Secrets.data_path(environment)
    encrypted = Secrets.encrypt_data(data, environment)
    File.write(path, encrypted)
  end

  protected def self.encrypt_data(data : String, environment : String) : String
    cipher = Secrets.new_cipher
    cipher.encrypt
    cipher.key = Secrets.key(environment)

    encrypted = String.new(cipher.update(data)) + String.new(cipher.final)
    Base64.strict_encode(encrypted)
  end

  protected def self.decrypt_data(data : String, environment : String) : String
    decipher = Secrets.new_cipher
    decipher.decrypt
    decipher.key = Secrets.key(environment)

    plain = Base64.decode_string(data)
    String.new(decipher.update(plain)) + String.new(decipher.final)
  end

  protected def self.key(environment : String) : String
    path = key_path(environment)
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

  protected def self.data_path(environment : String) : String
    "config/secrets/#{environment}.yml.enc"
  end

  protected def self.key_path(environment : String) : String
    "config/secrets/#{environment}.key"
  end
end
