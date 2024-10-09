# HTTPS server for `did:web` testing
## Overview
This repo provides a means for creating `did:web` served locally over HTTPS.
This allows `did:web` resolution between docker containers to be tested without
having to create real `did:web` objects.  It is NOT intended for generating
'real' `did:web` objects.

## Usage
### Create a DID
Run the `create-did.sh` script for each user who needs one, e.g.
```bash
./create-did.sh alice http://localhost:5002
```
where the first argument is a user identifier (e.g. their docker container's name)
and the second is the service endpoint that implements the DIDComm API.

This creates `did:web:didwebserver:dids:alice` and displays to `stdout` the
corresponding private key.  The displayed private key is not permanently stored
on disk, so it must be copied from the terminal output.

You can use this to create multiple `did:web` objects (one for each user you are
testing).  They will be served as e.g.
`https://localhost:443/dids/alice/did.json` or, from a docker container on the
same network, `https://didwebserver/dids/alice/did.json`.

### Modify the `docker-compose.yml` file
Ensure the `docker-compose.yml` file will be on the same network as the docker
containers that need to resolve `did:web`.  You can do this by changing
`default` below to the name of your docker network.
```yaml
...
networks:
  default:
    external: true
...
```

Docker containers on the same network can resolve IP addresses from container
names, which means the certificate issued to a server with Common Name
`didwebserver` (see below) will be successfully authenticated through the
generated certificate by docker containers on the same network.

If you have other services listening on port 443, you can remove the port
mapping since the docker containers will still be able to resolve within the
docker network (but it can be useful for debugging to check that the DIDs are
being served correctly from the host).

### Run nginx
Run `docker compose up -d` from the repository root to run the web server to
serve the DID(s).  Each time the container starts, it runs the script in
`./ssl/didwebserver/create-certificate.sh`, which generates:
- A self-signed Certificate Authority (CA) certificate `./ssl/didwebserver/ta.crt`
- A certificate issued by this CA to the nginx webserver called `didwebserver`,
  `./ssl/didwebserver/didwebserver.crt`

Note that this means that if you restart the nginx container, you need to
restart any container that depends on the CA certificate since it will change.
This behaviour is by design to reduce the chance that the self-signed
certificates are used in production.

### Make the new self-signed CA certificate trusted
Add the new self-signed CA to the docker containers that need to resolve
`did:web`.  For a container based on
[credo-ts](https://github.com/openwallet-foundation/credo-ts), the following
suffices:

```yaml
    ...
    volumes:
      - ...
      - path_to_did-web-server/ssl/ta.crt:/etc/ssl/didwebserver/ta.crt 
    ...
    environment:
      - ...
      - NODE_EXTRA_CA_CERTS=/etc/ssl/didwebserver/ta.crt
```
