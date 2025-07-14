oc create imagestream msr-contact-management

oc create serviceaccount image-puller-sa
oc policy add-role-to-user system:image-puller system:serviceaccount:${OCP_NAMESPACE}:image-puller-sa

oc create serviceaccount image-pusher-sa
oc policy add-role-to-user system:image-pusher system:serviceaccount:${OCP_NAMESPACE}:image-pusher-sa

export OCP_CR_USERNAME=$(oc create token image-pusher-sa --duration=876h)

oc delete secret cr-regcred
oc create secret docker-registry cr-regcred --docker-server=${OCP_CR_SERVER}/${OCP_NAMESPACE} --docker-username=image-puller-sa --docker-password=$(oc create token image-puller-sa --duration=876h)
podman login ${OCP_CR_SERVER}/${OCP_NAMESPACE} -u image-puller-sa -p ${OCP_CR_USERNAME}


oc adm policy add-scc-to-user privileged -z msr-contact-management

oc apply -f ./resources/helm/msr-secrets.yaml
oc create secret generic sttlab-keystore --from-file=$HOME/tls/sttlab.eu.jks
oc apply -f ./resources/helm/msr-service.yaml

helm upgrade --install contact-management webmethods/microservicesruntime -f ./resources/helm/msr-values.yaml

oc apply -f ./resources/helm/msr-route.yaml