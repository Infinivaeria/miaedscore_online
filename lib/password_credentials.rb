require 'base64'
require 'openssl'
require 'securerandom'

module PasswordCredentials
  PREFIX = '$pbkdf2-sha256$'.freeze
  ITERATIONS = 600_000
  SALT_BYTES = 16
  KEY_BYTES = 32

  def self.create(password)
    salt = SecureRandom.random_bytes(SALT_BYTES)
    key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, ITERATIONS, KEY_BYTES, 'sha256')
    "#{PREFIX}#{ITERATIONS}$#{Base64.strict_encode64(salt)}$#{Base64.strict_encode64(key)}"
  end

  def self.valid?(stored, password)
    return false unless stored.is_a?(String) && password.is_a?(String)

    unless stored.start_with?(PREFIX)
      return stored.bytesize == password.bytesize && OpenSSL.fixed_length_secure_compare(stored, password)
    end

    parts = stored.delete_prefix(PREFIX).split('$', -1)
    return false unless parts.length == 3 && parts[0] == ITERATIONS.to_s

    _, encoded_salt, encoded_key = parts

    salt = Base64.strict_decode64(encoded_salt)
    expected = Base64.strict_decode64(encoded_key)
    return false unless salt.bytesize == SALT_BYTES && expected.bytesize == KEY_BYTES

    actual = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, ITERATIONS, KEY_BYTES, 'sha256')
    OpenSSL.fixed_length_secure_compare(expected, actual)
  rescue ArgumentError
    false
  end
end
