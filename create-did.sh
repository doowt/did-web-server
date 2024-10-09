#!/bin/bash

# Creates did:web for $1 and puts it in ./html/dids/$1/did.json to
# be served by nginx over HTTPS, and outputs the private key to stout

if [[ $# < 2 ]]
then
    echo "Usage: ./create-did.sh <entity name> <service endpoint>"
    echo "E.g. ./create-did.sh alice http://localhost:5002"
    exit 1
fi

private_key_file=$(mktemp)
public_key_file=$(mktemp)

openssl genpkey -algorithm ed25519 -outform DER -out ${private_key_file}
openssl pkey -in $private_key_file -inform DER -pubout -outform DER > ${public_key_file}

private_key=$(tail -c32 $private_key_file | basenc --base64url | sed 's/\=//g')
public_key=$(tail -c32 $public_key_file | basenc --base64url | sed 's/\=//g')

entity_name=$1
did_web_id=did:web:didwebserver:dids:$entity_name
service_endpoint="$2"

[[ -d ./html/dids/$entity_name ]] || mkdir -p ./html/dids/$entity_name

echo -e "{
  \"@context\": [
    \"https://www.w3.org/ns/did/v1\",
    \"https://w3id.org/security/suites/jws-2020/v1\"
  ],
  \"id\": \"$did_web_id\",
  \"verificationMethod\": [
    {
      \"id\": \"$did_web_id#owner\",
      \"type\": \"JsonWebKey2020\",
      \"controller\": \"$did_web_id\",
      \"publicKeyJwk\": {
        \"kty\": \"OKP\",
        \"crv\": \"Ed25519\",
        \"x\": \"$public_key\"
      }
    }
  ],
  \"authentication\": [\"$did_web_id#owner\"],
  \"assertionMethod\": [\"$did_web_id#owner\"],
  \"services\": [
    {
      \"id\": \"$did_web_id#did-communication\",
      \"type\": \"did-communication\",
      \"priority\": 0,
      \"recipientKeys\": [
        \"$did_web_id#owner\"
      ],
      \"routingKeys\": [],
      \"accept\": [\"didcomm/aip1\"],
      \"serviceEndpoint\": \"$service_endpoint\"
    }
  ]
}" > ./html/dids/$entity_name/did.json

echo -e "Private key (copy this now - not stored in file): $private_key"
echo -e -n "DID: $did_web_id"

shred -u $private_key_file
rm $public_key_file