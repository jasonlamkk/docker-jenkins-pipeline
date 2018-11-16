#createFoldersMac.sh
DOCKER_HOST_BASE=/private

sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/documents

sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/home

sudo mkdir -p ${DOCKER_HOST_BASE}/jenkins/.ssh

sudo chown -R $(whoami) ${DOCKER_HOST_BASE}/jenkins

sudo mkdir -p ${DOCKER_HOST_BASE}/selenium/firefox/shm

sudo mkdir -p ${DOCKER_HOST_BASE}/selenium/chrome/shm

sudo chown -R $(whoami) ${DOCKER_HOST_BASE}/selenium