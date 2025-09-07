IMAGE_NAME=ghcr.io/staillanibm/msr-contact-management
TAG=latest
DOCKER_ROOT_URL=http://localhost:15555
DOCKER_ADMIN_PASSWORD=Manage123
KUBE_ROOT_URL=https://contact-management-int.sttlab.local
KUBE_ADMIN_PASSWORD=Manage12345

docker-build:
	docker build -t $(IMAGE_NAME):$(TAG) --platform=linux/amd64 --build-arg WPM_TOKEN=${WPM_TOKEN} --build-arg GIT_TOKEN=${GIT_TOKEN} .

docker-login-whi:
	@echo ${WHI_CR_PASSWORD} | docker login ${WHI_CR_SERVER} -u ${WHI_CR_USERNAME} --password-stdin

docker-login-gh:
	@echo ${GH_CR_PASSWORD} | docker login ${GH_CR_SERVER} -u ${GH_CR_USERNAME} --password-stdin

docker-push:
	docker push $(IMAGE_NAME):$(TAG)

docker-run:
	IMAGE_NAME=${IMAGE_NAME} TAG=${TAG}	docker-compose -f ./resources/docker-compose/docker-compose.yml up -d

docker-stop:
	IMAGE_NAME=${IMAGE_NAME} TAG=${TAG}	docker-compose -f ./resources/docker-compose/docker-compose.yml down

docker-logs:
	docker logs msr-contact-management

docker-logs-f:
	docker logs -f msr-contact-management

docker-test:
	newman run ./resources/tests/ContactManagementAutomated.postman_collection.json \
          --env-var "url=${DOCKER_ROOT_URL}/rad/sttContactManagement.api:ContactManagementAPI" \
          --env-var "userName=Administrator" \
          --env-var "password=${DOCKER_ADMIN_PASSWORD}" \
          --insecure

ocp-login:
	@oc login ${OCP_API_URL} -u ${OCP_USERNAME} -p ${OCP_PASSWORD}

kube-test:
	newman run ./resources/tests/ContactManagementAutomated.postman_collection.json \
          --env-var "url=${KUBE_ROOT_URL}/rad/sttContactManagement.api:ContactManagementAPI" \
          --env-var "userName=Administrator" \
          --env-var "password=${KUBE_ADMIN_PASSWORD}" \
          --insecure

kube-restart:
	kubectl rollout restart deployment stt-contact-management -n integration

kube-get-pods:
	kubectl get pods -l app=stt-contact-management -n integration

kube-logs-f:
	kubectl logs -l app=stt-contact-management -n integration --all-containers=true -f --prefix

