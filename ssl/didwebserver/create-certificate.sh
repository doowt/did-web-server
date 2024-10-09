#!/bin/bash

# Create trust anchor
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 90 -subj "/C=GB/O=Test Org/OU=Test OU/CN=DEV Trust Anchor" -keyout ta.key -out ta.crt

# Create CSR
openssl req -new -nodes -newkey rsa:2048 -subj "/C=GB/O=Test Org/OU=Test OU/CN=didwebserver" -addext "subjectAltName = DNS:didwebserver" -keyout didwebserver.key -out didwebserver.csr

# Sign CSR
openssl x509 -req -in didwebserver.csr -days 365 -CA ta.crt -CAkey ta.key -CAcreateserial -out didwebserver.crt