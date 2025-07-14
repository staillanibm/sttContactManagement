newman run ContactManagementAutomated.postman_collection.json \
          --env-var "url=$ROOT_URL/rad/sttContactManagement.api:ContactManagementAPI" \
          --env-var "userName=Administrator" \
          --env-var "password=$ADMIN_PASSWORD" \
          --insecure