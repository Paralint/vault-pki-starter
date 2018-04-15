disable_mlock=true

storage "consul" {
  address = "127.0.0.1:8500/"
}

ui = true

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable="true"
  # tls_cert_file = "certificates/vault/vault.cert.pem"
  # tls_key_file = "certificates/vault/vault.decrypted.key.pem"
}
