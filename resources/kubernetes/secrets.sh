# Create the secret to access the SAG image registry
kubectl create secret docker-registry sagregcred \
    --docker-server=${SAG_ACR_URL} \
    --docker-username=${SAG_ACR_USERNAME} \
    --docker-password=${SAG_ACR_PASSWORD} \
    --docker-email=${SAG_ACR_EMAIL_ADDRESS}  || exit 1

# Create the TLS secret used by the Ingress for TLS termination
kubectl create secret tls certificate \
    --key="${TLS_PRIVATEKEY_FILE_PATH}" \
    --cert="${TLS_PUBLICKEY_FILE_PATH}" || exit 1

# Create the license secret
kubectl create secret generic licenses \
    --from-file=msr-license=${MSR_LICENSE_FILE_PATH} \
    --from-file=um-license=${UM_LICENSE_FILE_PATH} || exit 1

# Create the microservice secret to connect to various satellite resources
kubectl create secret generic contact-management \
	--from-literal=ADMIN_PASSWORD=${MSR_ADMIN_PASSWORD} \
	--from-literal=DB_USERNAME=${POSTGRES_USERNAME} \
	--from-literal=DB_PASSWORD=${POSTGRES_PASSWORD} || exit 1