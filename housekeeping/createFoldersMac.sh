#createFoldersMac.sh
DOCKER_HOST_BASE=/private

if [ -z "${JENKIN_FOLDER}" ]; then 
    DATA_FOLDER=${DOCKER_HOST_BASE}/jenkins
else 
    DATA_FOLDER=${DOCKER_HOST_BASE}/${JENKIN_FOLDER}
fi

sudo mkdir -p ${DATA_FOLDER}/documents
echo "Created documents folder for Jenkins on : ${DATA_FOLDER}/documents"

sudo mkdir -p ${DATA_FOLDER}/home
echo "Created home folder for Jenkins on : ${DATA_FOLDER}/home"

sudo mkdir -p ${DATA_FOLDER}/.ssh
echo "Created SSH configuration folder for Jenkins on : ${DATA_FOLDER}/.ssh"

sudo chown -R $(whoami) ${DATA_FOLDER}
echo "Changed the owner of Jenkins folders to $(whoami)"

sudo mkdir -p ${DOCKER_HOST_BASE}/selenium/firefox/shm
sudo mkdir -p ${DOCKER_HOST_BASE}/selenium/chrome/shm
echo "Created folders for selenium on ${DOCKER_HOST_BASE}/selenium "

sudo chown -R $(whoami) ${DOCKER_HOST_BASE}/selenium
echo "Changed the owner of selenium folders to $(whoami)"