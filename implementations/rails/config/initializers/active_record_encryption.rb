# frozen_string_literal: true

require "openssl"

base_secret = Rails.application.secret_key_base
primary_key = OpenSSL::KDF.hkdf(base_secret, salt: "crmthree-ar-encryption", info: "primary", length: 32, hash: "SHA256")
deterministic_key = OpenSSL::KDF.hkdf(base_secret, salt: "crmthree-ar-encryption", info: "deterministic", length: 32, hash: "SHA256")
key_derivation_salt = OpenSSL::KDF.hkdf(base_secret, salt: "crmthree-ar-encryption", info: "salt", length: 32, hash: "SHA256")

Rails.application.config.active_record.encryption.primary_key = primary_key
Rails.application.config.active_record.encryption.deterministic_key = deterministic_key
Rails.application.config.active_record.encryption.key_derivation_salt = key_derivation_salt
ActiveRecord::Encryption.configure(primary_key: primary_key, deterministic_key: deterministic_key,
  key_derivation_salt: key_derivation_salt)
