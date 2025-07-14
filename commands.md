## Login to the container registries

docker login $WHI_CR_SERVER -u $WHI_CR_USERNAME -p $WHI_CR_PASSWORD
docker login $GH_CR_SERVER -u $GH_CR_USERNAME -p $GH_CR_PASSWORD

## Creation of the TLS certificate used by the Ingress

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout $HOME/tls/sttlab.local.key \
  -out $HOME/tls/sttlab.local.crt \
  -days 1095 \
  -subj "/CN=*.sttlab.local" \
  -addext "subjectAltName=DNS:*.sttlab.local"
