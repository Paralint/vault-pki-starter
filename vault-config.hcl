disable_mlock=true

storage "raft" {
  path = "."
}

cluster_addr = "http://127.0.0.1:8210"
api_addr = "http://127.0.0.1:8200"

ui = true

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable="true"
  # tls_cert_file = "certificates/vault/vault.cert.pem"
  # tls_key_file = "certificates/vault/vault.decrypted.key.pem"
}
