#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}=== OpenShift Contact Management Deployment ===${NC}"
echo ""

# Check if .env file exists
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    echo -e "${RED}Error: .env file not found in ${SCRIPT_DIR}${NC}"
    echo "Please create a .env file based on .env.template"
    exit 1
fi

# Source environment variables
echo -e "${YELLOW}Loading environment variables from .env...${NC}"
source "${SCRIPT_DIR}/.env"

# Validate required variables
REQUIRED_VARS=(
    "GH_CR_SERVER" "GH_CR_USERNAME" "GH_CR_PASSWORD"
    "DB_SERVER_NAME" "DB_PORT" "DB_DATABASE_NAME" "DB_USERNAME" "DB_PASSWORD"
    "ADMIN_PASSWORD"
    "ES_BOOTSTRAP_URL" "ES_USERNAME" "ES_PASSWORD" "ES_TRUSTSTORE_PASSWORD" "ES_TRUSTSTORE_LOCATION"
    "EEM_BOOTSTRAP_URL" "EEM_USERNAME" "EEM_PASSWORD" "EEM_TRUSTSTORE_PASSWORD" "EEM_TRUSTSTORE_LOCATION"
    "SAG_IS_CLOUD_REGISTER_URL" "SAG_IS_EDGE_CLOUD_ALIAS" "SAG_IS_CLOUD_REGISTER_TOKEN"
)

echo -e "${YELLOW}Validating required environment variables...${NC}"
MISSING_VARS=()
for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING_VARS+=("$VAR")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required environment variables:${NC}"
    for VAR in "${MISSING_VARS[@]}"; do
        echo -e "  - ${VAR}"
    done
    exit 1
fi

echo -e "${GREEN}All required variables are set${NC}"
echo ""

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating namespace 'contact'...${NC}"
oc create namespace contact --dry-run=client -o yaml | oc apply -f -

# Helper function to manage secrets idempotently
create_or_update_secret() {
    local secret_name=$1
    local secret_type=$2
    shift 2
    local args=("$@")

    echo "  - Managing ${secret_name} secret..."

    # Check if secret exists
    if oc get secret "${secret_name}" -n contact &>/dev/null; then
        echo "    Secret exists, deleting before recreate..."
        oc delete secret "${secret_name}" -n contact
    fi

    # Create the secret
    if [ "${secret_type}" = "docker-registry" ]; then
        oc create secret docker-registry "${secret_name}" "${args[@]}" --namespace=contact
    else
        oc create secret generic "${secret_name}" "${args[@]}" --namespace=contact
    fi
}

# Create secrets
echo -e "${YELLOW}Managing secrets (idempotent)...${NC}"

# Image pull secret for GitHub Container Registry
create_or_update_secret regcred docker-registry \
    --docker-server="${GH_CR_SERVER}" \
    --docker-username="${GH_CR_USERNAME}" \
    --docker-password="${GH_CR_PASSWORD}"

# Postgres secret
create_or_update_secret postgres generic \
    --from-literal=DB_USERNAME="${DB_USERNAME}" \
    --from-literal=DB_PASSWORD="${DB_PASSWORD}"

# Microservice secret
create_or_update_secret stt-contact-management generic \
    --from-literal=ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
    --from-literal=DB_SERVER_NAME="${DB_SERVER_NAME}" \
    --from-literal=DB_PORT="${DB_PORT}" \
    --from-literal=DB_DATABASE_NAME="${DB_DATABASE_NAME}" \
    --from-literal=DB_USERNAME="${DB_USERNAME}" \
    --from-literal=DB_PASSWORD="${DB_PASSWORD}" \
    --from-literal=ES_BOOTSTRAP_URL="${ES_BOOTSTRAP_URL}" \
    --from-literal=ES_USERNAME="${ES_USERNAME}" \
    --from-literal=ES_PASSWORD="${ES_PASSWORD}" \
    --from-literal=ES_TRUSTSTORE_PASSWORD="${ES_TRUSTSTORE_PASSWORD}" \
    --from-literal=EEM_BOOTSTRAP_URL="${EEM_BOOTSTRAP_URL}" \
    --from-literal=EEM_USERNAME="${EEM_USERNAME}" \
    --from-literal=EEM_PASSWORD="${EEM_PASSWORD}" \
    --from-literal=EEM_TRUSTSTORE_PASSWORD="${EEM_TRUSTSTORE_PASSWORD}" \
    --from-literal=SAG_IS_CLOUD_REGISTER_URL="${SAG_IS_CLOUD_REGISTER_URL}" \
    --from-literal=SAG_IS_EDGE_CLOUD_ALIAS="${SAG_IS_EDGE_CLOUD_ALIAS}" \
    --from-literal=SAG_IS_CLOUD_REGISTER_TOKEN="${SAG_IS_CLOUD_REGISTER_TOKEN}"

# Event Streams Truststore secret
if [ ! -f "${ES_TRUSTSTORE_LOCATION}" ]; then
    echo -e "${RED}Error: Event Streams truststore file not found at ${ES_TRUSTSTORE_LOCATION}${NC}"
    exit 1
fi
create_or_update_secret es-truststore generic \
    --from-file=es-cert.p12="${ES_TRUSTSTORE_LOCATION}"

# Event Endpoint Management Truststore secret
if [ ! -f "${EEM_TRUSTSTORE_LOCATION}" ]; then
    echo -e "${RED}Error: EEM truststore file not found at ${EEM_TRUSTSTORE_LOCATION}${NC}"
    exit 1
fi
create_or_update_secret eem-truststore generic \
    --from-file=eem-cert.jks="${EEM_TRUSTSTORE_LOCATION}"

echo -e "${GREEN}Secrets managed successfully${NC}"
echo ""

# Deploy using Kustomize
echo -e "${YELLOW}Deploying resources using Kustomize...${NC}"
oc apply -k "${SCRIPT_DIR}/base"

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "To check the deployment status:"
echo "  oc get all -n contact"
echo ""
echo "To get the route URL:"
echo "  oc get route stt-contact-management -n contact -o jsonpath='{.spec.host}'"
echo ""
echo "To view logs:"
echo "  oc logs -f deployment/stt-contact-management -n contact"
