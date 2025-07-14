newman run ContactManagementAutomated.postman_collection.json -e ContactManagement.postman_environment.json \
          --env-var "url=$ROOT_URL/rad/qdtContactManagement.api:ContactManagementAPI" \
          --env-var "userName=Administrator" \
          --env-var "password=$ADMIN_PASSWORD" \
          --insecure