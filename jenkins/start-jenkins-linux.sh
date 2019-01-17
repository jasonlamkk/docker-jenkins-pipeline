#start-jenkins.sh
BASE=~/cicd
if [ -z "${JENKIN_DOCKER_HTTP_PORT}" ]; then 
    HTTP_PORT=4080
else 
    HTTP_PORT=${JENKIN_DOCKER_HTTP_PORT}
fi

if [ -z "${JENKIN_DOCKER_DATA}" ]; then 
    DATA_FOLDER=${BASE}/jenkins/home
else 
    DATA_FOLDER=${JENKIN_DOCKER_DATA}
fi

if [ -z "${JENKIN_DOCKER_HOME}" ]; then 
    HOME_FOLDER=${BASE}/jenkins/documents
else 
    HOME_FOLDER=${JENKIN_DOCKER_HOME}
fi

if [ -z "${HOST_DOCKER_SOCKET}" ]; then 
    DOCKER_SOCKET=/var/run/docker.sock
else 
    DOCKER_SOCKET=${HOST_DOCKER_SOCKET}
fi

if [ -z "${JENKIN_SSH_HOME}" ]; then
    SSH_HOME=${BASE}/jenkins/.ssh
else 
    SSH_HOME=${JENKIN_SSH_HOME}
fi

if [ -z "${JENKIN_INST_NAME}" ]; then
    INST_NAME=local_jenkins
else 
    INST_NAME=${JENKIN_INST_NAME}
fi
#start docker
docker run --rm -d --name ${INST_NAME} -u root -p ${HTTP_PORT}:8080 -v ${SSH_HOME}:/root/.ssh -v ${DATA_FOLDER}:/var/jenkins_home -v ${DOCKER_SOCKET}:/var/run/docker.sock -v ${HOME_FOLDER}:/home jenkinsci/blueocean

#check and create ssh key, then print it
docker exec ${INST_NAME} cat /root/.ssh/id_rsa.pub || \
    ( docker exec ${INST_NAME} mkdir -p /root/.ssh && \
        docker exec ${INST_NAME} ssh-keygen -t rsa -f /root/.ssh/id_rsa && \
        docker exec ${INST_NAME} cat /root/.ssh/id_rsa.pub )

#setup SSH public key
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
docker cp "${DIR}/ssh-client-init.sh" ${INST_NAME}:ssh-client-init.sh
docker exec ${INST_NAME} bash ssh-client-init.sh

#check need to use initialAdminPassword
docker cp "${DIR}/find-init-password.sh" ${INST_NAME}:find-init-password.sh
docker exec ${INST_NAME} bash find-init-password.sh

