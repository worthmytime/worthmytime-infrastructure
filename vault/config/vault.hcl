ui = true

storage "file" {
  path = "/vault/file"
}

# TLS wyłączony, bo port jest wystawiony wyłącznie na 127.0.0.1 hosta (patrz docker-compose.yml).
# Dostęp z zewnątrz: reverse proxy z TLS albo tunel SSH.
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://127.0.0.1:8200"
