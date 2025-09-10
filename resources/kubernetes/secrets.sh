source .env

# Create the secret to access the IBM WHI image registry
kubectl create secret docker-registry ibm-regcred \
    --docker-server=${WHI_CR_SERVER} \
    --docker-username=${WHI_CR_USERNAME} \
    --docker-password=${WHI_CR_PASSWORD}

# Create the secret to access the webMethods image registry
kubectl create secret docker-registry wm-regcred \
    --docker-server=${WM_CR_SERVER} \
    --docker-username=${WM_CR_USERNAME} \
    --docker-password=${WM_CR_PASSWORD}

# Create the secret to access the image registry where the microservice image is located
kubectl create secret docker-registry regcred \
    --docker-server=${GH_CR_SERVER} \
    --docker-username=${GH_CR_USERNAME} \
    --docker-password=${GH_CR_PASSWORD}

# Create the TLS secret used by the Ingress for TLS termination
kubectl create secret tls tls-cert \
    --key="${TLS_PRIVATEKEY_FILE_PATH}" \
    --cert="${TLS_PUBLICKEY_FILE_PATH}"

# Create the microservice secret to connect to various satellite resources
kubectl create secret generic stt-contact-management \
	--from-literal=ADMIN_PASSWORD=${ADMIN_PASSWORD} \
	--from-literal=DB_SERVER_NAME=${DB_SERVER_NAME} \
	--from-literal=DB_PORT=${DB_PORT} \
    --from-literal=DB_DATABASE_NAME=${DB_DATABASE_NAME} \
    --from-literal=DB_USERNAME=${DB_USERNAME} \
    --from-literal=DB_PASSWORD=${DB_PASSWORD} \
    --from-literal=JNDI_URL=${JNDI_URL} \
    --from-literal=ES_BOOTSTRAP_URL=${ES_BOOTSTRAP_URL} \
    --from-literal=ES_USERNAME=${ES_USERNAME} \
    --from-literal=ES_PASSWORD=${ES_PASSWORD} \
    --from-literal=ES_TRUSTSTORE_PASSWORD=${ES_TRUSTSTORE_PASSWORD} \
    --from-literal=EEM_BOOTSTRAP_URL=${EEM_BOOTSTRAP_URL} \
    --from-literal=EEM_USERNAME=${EEM_USERNAME} \
    --from-literal=EEM_PASSWORD=${EEM_PASSWORD} \
    --from-literal=EEM_TRUSTSTORE_PASSWORD=${EEM_TRUSTSTORE_PASSWORD}

# Create the Postgres secret
kubectl create secret generic postgres \
    --from-literal=DB_USERNAME=${DB_USERNAME} \
    --from-literal=DB_PASSWORD=${DB_PASSWORD} 

# Create the Event Streams Truststore secret
kubectl create secret generic es-truststore \
  --from-file=es-cert.p12=${ES_TRUSTSTORE_LOCATION}

# Create the Event Endpoint Management Truststore secret
kubectl create secret generic eem-truststore \
  --from-file=eem-cert.jks=${EEM_TRUSTSTORE_LOCATION}