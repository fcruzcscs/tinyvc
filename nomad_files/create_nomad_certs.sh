#!/bin/bash

# Set working directory for certificates
CERT_DIR="certs"
mkdir -p $CERT_DIR
cd $CERT_DIR
pwd

# Generate a Certificate Authority (CA)
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/CN=nomad-ca" -keyout nomad-ca.key -out nomad-ca.pem

# Create an OpenSSL config file for SAN support
cat <<EOF > openssl-nomad.cnf
[ req ]
default_bits       = 4096
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
commonName = Nomad Server

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = 127.0.0.1
EOF

# Generate a private key for the Nomad server
openssl genrsa -out nomad-server.key 4096

# Create a Certificate Signing Request (CSR)
openssl req -new -key nomad-server.key -subj "/CN=nomad-server" \
    -out nomad-server.csr -config openssl-nomad.cnf

# Sign the server certificate with the CA, ensuring SAN support
openssl x509 -req -in nomad-server.csr -CA nomad-ca.pem -CAkey nomad-ca.key -CAcreateserial \
    -out nomad-server.pem -days 365 -sha256 \
    -extensions v3_req -extfile openssl-nomad.cnf

# Output the generated files
echo "Certificates generated successfully in $CERT_DIR"
ls -l ../$CERT_DIR

