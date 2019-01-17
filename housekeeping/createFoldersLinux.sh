#createFoldersMac.sh
DOCKER_HOST_BASE=~/cicd

if [ -z "${JENKIN_FOLDER}" ]; then 
    DATA_FOLDER=${DOCKER_HOST_BASE}/jenkins
else 
    DATA_FOLDER=${DOCKER_HOST_BASE}/${JENKIN_FOLDER}
fi

sudo mkdir -p ${DATA_FOLDER}/documents

sudo mkdir -p ${DATA_FOLDER}/home

sudo mkdir -p ${DATA_FOLDER}/.ssh

sudo chown -R $(whoami) ${DATA_FOLDER}

sudo mkdir -p ${DOCKER_HOST_BASE}/selenium/firefox/shm

sudo mkdir -p ${DOCKER_HOST_BASE}/selenium/chrome/shm

sudo chown -R $(whoami) ${DOCKER_HOST_BASE}/selenium
